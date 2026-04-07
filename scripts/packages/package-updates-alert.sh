#!/bin/bash

set -u

WARNING_THRESHOLD="${1:-5}"
CRITICAL_THRESHOLD="${2:-20}"
LOG_FILE="${3:-$HOME/project-5-personal-maintenance-tracker/runtime-logs/package-updates.log}"

if ! command -v apt >/dev/null 2>&1; then
  echo "ERROR: apt not available"
  exit 1
fi

if ! [[ "$WARNING_THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "ERROR: warning threshold must be integer"
  exit 1
fi

if ! [[ "$CRITICAL_THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "ERROR: critical threshold must be integer"
  exit 1
fi

UPGRADABLE_OUTPUT=$(apt list --upgradable 2>/dev/null)
UPGRADABLE_COUNT=$(echo "$UPGRADABLE_OUTPUT" | tail -n +2 | sed '/^\s*$/d' | wc -l)

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

STATUS="OK"
MESSAGE="No updates needed"

if [ "$UPGRADABLE_COUNT" -ge "$CRITICAL_THRESHOLD" ]; then
  STATUS="CRITICAL"
  MESSAGE="Too many updates pending"
elif [ "$UPGRADABLE_COUNT" -ge "$WARNING_THRESHOLD" ]; then
  STATUS="WARNING"
  MESSAGE="Updates available"
fi

echo "== Package updates alert =="
echo "timestamp=$TIMESTAMP"
echo "updates=$UPGRADABLE_COUNT"
echo "warning_threshold=$WARNING_THRESHOLD"
echo "critical_threshold=$CRITICAL_THRESHOLD"
echo "status=$STATUS"
echo "message=$MESSAGE"

mkdir -p "$(dirname "$LOG_FILE")"

echo "timestamp=\"$TIMESTAMP\" updates=$UPGRADABLE_COUNT status=$STATUS message=\"$MESSAGE\"" >> "$LOG_FILE"

if [ "$STATUS" = "OK" ]; then
  exit 0
elif [ "$STATUS" = "WARNING" ]; then
  exit 1
else
  exit 2
fi
