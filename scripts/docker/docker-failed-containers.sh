#!/bin/bash

set -u

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed"
  exit 1
fi

echo "== Failed / Stopped containers =="

docker ps -a --filter "status=exited" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
