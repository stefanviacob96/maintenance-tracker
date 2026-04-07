#!/bin/bash

set -u

SERVICE_NAME="${1:-cron}"
LOG_FILE="${2:-$HOME/project-5-personal-maintenance-tracker/runtime-logs/service-alert.log}"

if ! command -v pgrep >/dev/null 2>&1; then
  echo "ERROR: 'pgrep' command is not available"
  exit 1
fi

if [ -z "$SERVICE_NAME" ]; then
  echo "ERROR: service name cannot be empty"
  exit 1
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if pgrep -x "$SERVICE_NAME" >/dev/null 2>&1; then
  echo "OK: service/process '$SERVICE_NAME' is running at $TIMESTAMP"
  exit 0
else
  MESSAGE="ALERT: service/process '$SERVICE_NAME' is NOT running at $TIMESTAMP"
  echo "$MESSAGE"
  echo "$MESSAGE" >> "$LOG_FILE"
  exit 1
fi
