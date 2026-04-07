#!/bin/bash

set -u

TARGET="${1:-8.8.8.8}"
COUNT="${2:-4}"

if ! command -v ping >/dev/null 2>&1; then
  echo "ERROR: 'ping' command is not available"
  exit 1
fi

if [ -z "$TARGET" ]; then
  echo "ERROR: target must not be empty"
  exit 1
fi

if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: count must be an integer"
  exit 1
fi

if [ "$COUNT" -le 0 ]; then
  echo "ERROR: count must be greater than 0"
  exit 1
fi

PING_OUTPUT=$(ping -c "$COUNT" -W 2 "$TARGET" 2>/dev/null)
PING_EXIT_CODE=$?

echo "== Ping check =="
echo "target=$TARGET"
echo "count=$COUNT"

if [ "$PING_EXIT_CODE" -ne 0 ] && [ -z "$PING_OUTPUT" ]; then
  echo "status=CRITICAL"
  echo "message=Ping command failed or host is unreachable"
  exit 2
fi

PACKET_LOSS=$(echo "$PING_OUTPUT" | awk -F', ' '/packet loss/ {print $3}' | awk '{print $1}' | tr -d '%')

if ! [[ "${PACKET_LOSS:-}" =~ ^[0-9]+$ ]]; then
  echo "status=CRITICAL"
  echo "message=Could not determine packet loss"
  exit 2
fi

echo "packet_loss_percent=$PACKET_LOSS"

if [ "$PACKET_LOSS" -eq 0 ]; then
  echo "status=OK"
  echo "message=Ping successful with no packet loss"
  exit 0
fi

if [ "$PACKET_LOSS" -lt 100 ]; then
  echo "status=WARNING"
  echo "message=Partial packet loss detected"
  exit 1
fi

echo "status=CRITICAL"
echo "message=Host unreachable with 100 percent packet loss"
exit 2
