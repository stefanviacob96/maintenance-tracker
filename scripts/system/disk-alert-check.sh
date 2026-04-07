#!/bin/bash

set -u

THRESHOLD="${1:-80}"
TARGET_PATH="${2:-/}"
LOG_FILE="${3:-$HOME/project-5-personal-maintenance-tracker/runtime-logs/disk-alert.log}"

if ! command -v df >/dev/null 2>&1; then
  echo "ERROR: 'df' command is not available"
  exit 1
fi

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "ERROR: threshold must be an integer"
  exit 1
fi

USAGE_LINE=$(df -P "$TARGET_PATH" 2>/dev/null | awk 'NR==2 {print $5}')

if [ -z "$USAGE_LINE" ]; then
  echo "ERROR: could not read disk usage for path '$TARGET_PATH'"
  exit 1
fi

USAGE_PERCENT="${USAGE_LINE%\%}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if ! [[ "$USAGE_PERCENT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: disk usage is not a valid integer: $USAGE_PERCENT"
  exit 1
fi

if [ "$USAGE_PERCENT" -ge "$THRESHOLD" ]; then
  MESSAGE="ALERT: disk usage for $TARGET_PATH is ${USAGE_PERCENT}% (threshold=${THRESHOLD}%) at $TIMESTAMP"
  echo "$MESSAGE"
  echo "$MESSAGE" >> "$LOG_FILE"
  exit 1
else
  echo "OK: disk usage for $TARGET_PATH is ${USAGE_PERCENT}% (threshold=${THRESHOLD}%) at $TIMESTAMP"
  exit 0
fi
