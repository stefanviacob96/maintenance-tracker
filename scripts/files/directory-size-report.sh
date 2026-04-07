#!/bin/bash

set -u

TARGET_PATH="${1:-$HOME}"
LIMIT="${2:-10}"

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

echo "== Top $LIMIT directories/files in $TARGET_PATH by size =="

du -sh "$TARGET_PATH"/* 2>/dev/null | sort -hr | head -n "$LIMIT"
