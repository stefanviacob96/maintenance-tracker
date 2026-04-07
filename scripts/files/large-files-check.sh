#!/bin/bash

set -u

TARGET_PATH="${1:-$HOME}"
MIN_SIZE="${2:-100M}"
LIMIT="${3:-10}"

if ! command -v find >/dev/null 2>&1; then
  echo "ERROR: 'find' command is not available"
  exit 1
fi

if ! command -v du >/dev/null 2>&1; then
  echo "ERROR: 'du' command is not available"
  exit 1
fi

if ! command -v sort >/dev/null 2>&1; then
  echo "ERROR: 'sort' command is not available"
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

if ! [[ "$LIMIT" =~ ^[0-9]+$ ]]; then
  echo "ERROR: limit must be an integer"
  exit 1
fi

if [ "$LIMIT" -le 0 ]; then
  echo "ERROR: limit must be greater than 0"
  exit 1
fi

echo "== Large files in $TARGET_PATH (bigger than $MIN_SIZE, top $LIMIT) =="

find "$TARGET_PATH" -type f -size +"$MIN_SIZE" -exec du -h {} + 2>/dev/null | sort -hr | head -n "$LIMIT"
