#!/bin/bash

set -u

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed"
  exit 1
fi

DANGLING_IMAGES=$(docker images --filter "dangling=true" -q)

if [ -z "$DANGLING_IMAGES" ]; then
  echo "== Docker unused images check =="
  echo "unused_images_count=0"
  echo "status=OK"
  echo "message=No dangling images found"
  exit 0
fi

UNUSED_COUNT=$(echo "$DANGLING_IMAGES" | wc -l)

echo "== Docker unused images check =="
echo "unused_images_count=$UNUSED_COUNT"
echo "status=WARNING"
echo "message=Dangling images found"
echo
echo "== Dangling image IDs =="
echo "$DANGLING_IMAGES"
