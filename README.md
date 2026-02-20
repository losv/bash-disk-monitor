# Bash Disk Monitor

Simple disk usage monitoring script with logging and Telegram alerts.

## Features

- Checks disk usage using `df`
- Configurable WARNING and CRITICAL thresholds
- Logs to file
- Telegram notifications
- Anti-spam cooldown protection
- Configurable via external config file
- Safe Bash practices (`set -euo pipefail`)

---

## Project Structure

bash-disk-monitor/
├── LICENSE
├── README.md
├── config/
│ └── config.example.conf
├── scripts/
│ └── disk_check.sh

## Requirements

- Linux
- bash 4+
- curl
- awk

---
Create config file:

cp config/config.example.conf config/config.conf

Edit configuration:

nano config/config.conf
Configuration

Example config.conf:

TELEGRAM_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"

TW=80
TC=90

LOG_FILE="./disk_check.log"
STATE_DIR="./state"
COOLDOWN=3600
Usage

Run manually:

bash scripts/disk_check.sh

Example output:

/ (/dev/mapper/rl-root) - 86% [WARNING]
/boot (/dev/sda1) - 37% [OK]
/home (/dev/mapper/rl-home) - 57% [OK]
Running via Cron

Add to crontab:

crontab -e

Example (every 5 minutes):

*/5 * * * * /path/to/bash-disk-monitor/scripts/disk_check.sh
Security Notes

Real Telegram tokens are NOT stored in repository

config.conf should be added to .gitignore

Script uses strict mode (set -euo pipefail)

Telegram alerts protected by cooldown

Author
LosV
