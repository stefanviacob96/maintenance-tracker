#!/bin/bash

set -u

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed"
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "ERROR: docker daemon is not responding"
  exit 1
fi

TOTAL_CONTAINERS=$(docker ps -a -q | wc -l)
RUNNING_CONTAINERS=$(docker ps -q | wc -l)
EXITED_CONTAINERS=$(docker ps -a --filter "status=exited" -q | wc -l)

echo "== Docker health summary =="
echo "total_containers=$TOTAL_CONTAINERS"
echo "running_containers=$RUNNING_CONTAINERS"
echo "exited_containers=$EXITED_CONTAINERS"

if [ "$EXITED_CONTAINERS" -gt 0 ]; then
  echo "status=WARNING"
  echo "message=There are stopped containers to inspect"
else
  echo "status=OK"
  echo "message=No stopped containers found"
fi
