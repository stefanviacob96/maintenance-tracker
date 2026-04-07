#!/bin/bash

set -u

LIMIT="${1:-5}"

if ! command -v ps >/dev/null 2>&1; then
  echo "ERROR: 'ps' command is not available"
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

echo "== Top $LIMIT processes by memory usage =="
ps -eo pid,user,%mem,%cpu,comm --sort=-%mem | head -n $((LIMIT + 1))
