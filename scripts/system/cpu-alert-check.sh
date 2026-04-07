#!/bin/bash

set -u

THRESHOLD="${1:-80}"
LOG_FILE="${2:-$HOME/project-5-personal-maintenance-tracker/runtime-logs/cpu-alert.log}"

if ! command -v top >/dev/null 2>&1; then
  echo "ERROR: 'top' command is not available"
  exit 1
fi

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "ERROR: threshold must be an integer"
  exit 1
fi

CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | sed 's/,/./')
CPU_USAGE=$(awk "BEGIN {print 100 - $CPU_IDLE}")

CPU_USAGE_INT=$(printf "%.0f" "$CPU_USAGE")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ "$CPU_USAGE_INT" -ge "$THRESHOLD" ]; then
  MESSAGE="ALERT: CPU usage is ${CPU_USAGE_INT}% (threshold=${THRESHOLD}%) at $TIMESTAMP"
  echo "$MESSAGE"
  echo "$MESSAGE" >> "$LOG_FILE"
  exit 1
else
  echo "OK: CPU usage is ${CPU_USAGE_INT}% (threshold=${THRESHOLD}%) at $TIMESTAMP"
  exit 0
fi
