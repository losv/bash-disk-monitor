#!/usr/bin/env bash

# Disk Monitor Script
# Checks disk usage and sends Telegram alerts


set -euo pipefail

# === PATH TO CONFIG ===
CONFIG_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../config/config.conf"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    echo "Copy config/config.example.conf to config/config.conf"
    exit 1
fi

source "$CONFIG_FILE"

# === DEFAULT THRESHOLDS (can be overridden in config) ===
TW=${TW:-80}
TC=${TC:-90}

LOG_FILE=${LOG_FILE:-/var/log/disk_check.log}
STATE_DIR=${STATE_DIR:-/var/lib/disk_monitor}
COOLDOWN=${COOLDOWN:-3600}

# ============================================
# Utility functions


log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
}

get_level() {
    local usage=$1

    if (( usage >= TC )); then
        echo "CRITICAL"
    elif (( usage >= TW )); then
        echo "WARNING"
    else
        echo "OK"
    fi
}

can_send_alert() {
    local device="$1"
    local state_file="${STATE_DIR}/${device//\//_}.last"

    local now
    now=$(date +%s)

    local last_sent=0
    if [[ -f "$state_file" ]]; then
        last_sent=$(cat "$state_file" 2>/dev/null || echo 0)
    fi

    if (( now - last_sent > COOLDOWN )); then
        echo "$now" > "$state_file"
        return 0
    else
        local remaining=$((COOLDOWN - (now - last_sent)))
        log_message "Alert suppressed for $device (${remaining}s remaining)"
        return 1
    fi
}

send_alert() {
    local mount="$1"
    local device="$2"
    local usage="$3"

    if ! can_send_alert "$device"; then
        return
    fi

    local level
    level=$(get_level "$usage")

    [[ "$level" == "OK" ]] && return

    local emoji
    case "$level" in
        CRITICAL) emoji="🔴" ;;
        WARNING)  emoji="🟡" ;;
    esac

    local message
    message="${emoji} [${level}] ${emoji}%0A%0A"
    message+="Server: $(hostname)%0A"
    message+="Mount: ${mount}%0A"
    message+="Device: <code>${device}</code>%0A"
    message+="Usage: ${usage}%%0A"
    message+="Time: $(date '+%Y-%m-%d %H:%M:%S')"

    curl -s --max-time 10 \
        "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${message}" \
        -d "parse_mode=HTML" \
        -d "disable_web_page_preview=true" \
        > /dev/null 2>&1

    log_message "Telegram alert sent: $mount ($device) - ${usage}%"
}

# ============================================
# Pre-checks


mkdir -p "$STATE_DIR"

for cmd in df awk date curl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: Required command not found: $cmd" >&2
        exit 1
    fi
done

touch "$LOG_FILE" 2>/dev/null || {
    echo "ERROR: Cannot write to log file: $LOG_FILE" >&2
    exit 1
}

# ============================================
# Main logic

log_message "=== Disk check started ==="

df -hP | awk 'NR>1' | while read -r line; do

    device=$(awk '{print $1}' <<< "$line")
    percent=$(awk '{print $5}' <<< "$line")

    mount=$(awk '{
        for (i=6; i<=NF; i++) printf "%s ", $i;
        print ""
    }' <<< "$line" | sed 's/ $//')

    [[ -z "$mount" ]] && continue

    case "$device" in
        tmpfs|devtmpfs|udev) continue ;;
    esac

    usage=${percent%%%}

    [[ "$usage" =~ ^[0-9]+$ ]] || continue

    level=$(get_level "$usage")

    echo "$mount ($device) - ${usage}% [$level]"
    log_message "$mount ($device) - ${usage}% [$level]"

    if [[ "$level" == "WARNING" || "$level" == "CRITICAL" ]]; then
        send_alert "$mount" "$device" "$usage"
    fi

done

log_message "=== Disk check finished ==="
