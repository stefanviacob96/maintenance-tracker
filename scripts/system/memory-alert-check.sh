#!/bin/bash

set -u

THRESHOLD="${1:-75}"
LOG_FILE="${2:-$HOME/project-5-personal-maintenance-tracker/runtime-logs/memory-alert.log}"

if ! command -v free >/dev/null 2>&1; then
  echo "ERROR: 'free' command is not available"
  exit 1
fi

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "ERROR: threshold must be an integer"
  exit 1
fi

MEM_LINE=$(free | awk '/^Mem:/ {print $2, $3}')

if [ -z "$MEM_LINE" ]; then
  echo "ERROR: could not read memory usage"
  exit 1
fi

TOTAL_MEM=$(echo "$MEM_LINE" | awk '{print $1}')
USED_MEM=$(echo "$MEM_LINE" | awk '{print $2}')

if ! [[ "$TOTAL_MEM" =~ ^[0-9]+$ ]]; then
  echo "ERROR: failed to parse total memory"
  exit 1
fi

if ! [[ "$USED_MEM" =~ ^[0-9]+$ ]]; then
  echo "ERROR: failed to parse used memory"
  exit 1
fi

if [ "$TOTAL_MEM" -eq 0 ]; then
  echo "ERROR: total memory reported as zero"
  exit 1
fi

USED_PERCENT=$(( USED_MEM * 100 / TOTAL_MEM ))
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

mkdir -p "$(dirname "$LOG_FILE")"

if [ "$USED_PERCENT" -ge "$THRESHOLD" ]; then
  echo "ALERT: memory usage is ${USED_PERCENT}% (threshold=${THRESHOLD}%) at ${TIMESTAMP}" | tee -a "$LOG_FILE"
  exit 1
else
  echo "OK: memory usage is ${USED_PERCENT}% (threshold=${THRESHOLD}%) at ${TIMESTAMP}"
  exit 0
fi
