#!/bin/bash

set -u

LIMIT="${1:-5}"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed"
  exit 1
fi

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: limit must be an integer"
  exit 1
fi

if [ "$LIMIT" -le 0 ]; then
  echo "ERROR: limit must be greater than 0"
  exit 1
fi

echo "== Last $LIMIT failed containers =="

docker ps -a \
  --filter "status=exited" \
  --format "{{.Names}}\t{{.Status}}\t{{.RunningFor}}" \
  | head -n "$LIMIT"
