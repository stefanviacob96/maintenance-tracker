#!/bin/bash

set -u

TARGET_PATH="${1:-$HOME}"
AGE_DAYS="${2:-30}"
LIMIT="${3:-10}"

if ! command -v find >/dev/null 2>&1; then
  echo "ERROR: 'find' command is not available"
  exit 1
fi

if ! command -v xargs >/dev/null 2>&1; then
  echo "ERROR: 'xargs' command is not available"
  exit 1
fi

if ! command -v ls >/dev/null 2>&1; then
  echo "ERROR: 'ls' command is not available"
  exit 1
fi

if ! command -v head >/dev/null 2>&1; then
  echo "ERROR: 'head' command is not available"
  exit 1
fi

if [ ! -d "$TARGET_PATH" ]; then
  echo "ERROR: target path does not exist or is not a directory: $TARGET_PATH"
  exit 1
fi

if ! [[ "$AGE_DAYS" =~ ^[0-9]+$ ]]; then
  echo "ERROR: age_days must be an integer"
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

echo "== Files in $TARGET_PATH older than $AGE_DAYS days (top $LIMIT) =="

find "$TARGET_PATH" -type f -mtime +"$AGE_DAYS" -print0 2>/dev/null \
  | xargs -0 ls -lh 2>/dev/null \
  | head -n "$LIMIT"
