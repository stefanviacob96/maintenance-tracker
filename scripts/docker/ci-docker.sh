#!/bin/bash

set -e

IMAGE_NAME="personal-maintenance-tracker"
DOCKERHUB_IMAGE="iacobstev/personal-tracker-app"
APP_CONTAINER="personal-tracker-test"
DB_CONTAINER="personal-tracker-db"
NETWORK_NAME="personal-tracker-test-net"

if [ -z "$1" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

TAG="$1"

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "Cleaning old containers/network if they exist..."
docker rm -f "$APP_CONTAINER" "$DB_CONTAINER" 2>/dev/null || true
docker network rm "$NETWORK_NAME" 2>/dev/null || true

echo "Creating Docker network..."
docker network create "$NETWORK_NAME"

echo "Starting PostgreSQL test container..."
docker run -d \
  --name "$DB_CONTAINER" \
  --network "$NETWORK_NAME" \
  -e POSTGRES_DB=tracker \
  -e POSTGRES_USER=tracker \
  -e POSTGRES_PASSWORD=tracker \
  postgres:15

echo "Starting app test container..."
docker run -d \
  --name "$APP_CONTAINER" \
  --network "$NETWORK_NAME" \
  -p 5000:5000 \
  -e DB_TYPE=postgres \
  -e PG_HOST="$DB_CONTAINER" \
  -e PG_PORT=5432 \
  -e PG_DB=tracker \
  -e PG_USER=tracker \
  -e PG_PASSWORD=tracker \
  -e DB_CONNECT_RETRIES=10 \
  -e DB_CONNECT_DELAY=3 \
  "$IMAGE_NAME"

echo "Waiting for app to start..."
sleep 10

echo "Testing /health ..."
curl --fail http://localhost:5000/health

echo "Testing /assets ..."
curl --fail http://localhost:5000/assets

echo "Testing /tasks ..."
curl --fail http://localhost:5000/tasks

echo "Stopping and removing test containers..."
docker rm -f "$APP_CONTAINER" "$DB_CONTAINER"
docker network rm "$NETWORK_NAME"

echo "Tagging images..."
docker tag "$IMAGE_NAME" "$DOCKERHUB_IMAGE:$TAG"
docker tag "$IMAGE_NAME" "$DOCKERHUB_IMAGE:latest"

echo "Pushing images to Docker Hub..."
docker push "$DOCKERHUB_IMAGE:$TAG"
docker push "$DOCKERHUB_IMAGE:latest"

echo "Release completed successfully."
