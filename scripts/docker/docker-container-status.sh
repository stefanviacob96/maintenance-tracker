#!/bin/bash

set -u

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: 'docker' command is not available"
  exit 1
fi

echo "== Docker container status =="

docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
