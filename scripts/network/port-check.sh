#!/bin/bash

set -u

HOST="${1:-localhost}"
PORT="${2:-80}"
TIMEOUT="${3:-3}"

if ! command -v nc >/dev/null 2>&1; then
  echo "ERROR: 'nc' command is not available"
  exit 1
fi

if [ -z "$HOST" ]; then
  echo "ERROR: host must not be empty"
  exit 1
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: port must be an integer"
  exit 1
fi

if [ "$PORT" -le 0 ] || [ "$PORT" -gt 65535 ]; then
  echo "ERROR: port must be between 1 and 65535"
  exit 1
fi

if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: timeout must be an integer"
  exit 1
fi

if [ "$TIMEOUT" -le 0 ]; then
  echo "ERROR: timeout must be greater than 0"
  exit 1
fi

echo "== Port check =="
echo "host=$HOST"
echo "port=$PORT"
echo "timeout_seconds=$TIMEOUT"

if nc -z -w "$TIMEOUT" "$HOST" "$PORT" >/dev/null 2>&1; then
  echo "status=OK"
  echo "message=Port is open and reachable"
  exit 0
fi

echo "status=CRITICAL"
echo "message=Port is closed or unreachable"
exit 2
