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
