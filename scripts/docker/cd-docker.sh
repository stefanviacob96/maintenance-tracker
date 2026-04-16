#!/bin/bash
set -e

COMPOSE_FILE="docker-compose.yml"
APP_SERVICE="app"
APP_CONTAINER="personal-maintenance-tracker"
APP_URL="http://localhost:5000/health"
HEALTH_RETRIES=10
HEALTH_DELAY=3

if [ -z "$1" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

TAG="$1"
TARGET_IMAGE="iacobstev/personal-tracker-app:$TAG"

echo "Deploying Docker Compose with IMAGE_TAG=$TAG"

CURRENT_IMAGE="$(docker inspect --format='{{.Config.Image}}' "$APP_CONTAINER" 2>/dev/null || true)"

if [ -n "$CURRENT_IMAGE" ]; then
  echo "Current image: $CURRENT_IMAGE"
else
  echo "Current image: not found (container may not exist yet)"
fi

echo "Target image: $TARGET_IMAGE"

if [ "$CURRENT_IMAGE" = "$TARGET_IMAGE" ]; then
  echo "Image is already deployed. Skipping deployment."
  exit 0
fi

export IMAGE_TAG="$TAG"

echo "Pulling latest images..."
docker compose -f "$COMPOSE_FILE" pull

echo "Starting containers..."
docker compose -f "$COMPOSE_FILE" up -d

echo "Waiting for app to be ready..."

for i in $(seq 1 "$HEALTH_RETRIES"); do
  if curl --fail --silent "$APP_URL"; then
    echo
    echo "Health check passed."
    echo "Docker CD deployment completed successfully."
    exit 0
  fi

  echo "Health check attempt $i/$HEALTH_RETRIES failed. Retrying in $HEALTH_DELAY seconds..."
  sleep "$HEALTH_DELAY"
done

echo "Deployment failed: app did not become healthy."

if [ -n "$CURRENT_IMAGE" ]; then
  echo "Rolling back to previous image: $CURRENT_IMAGE"

  ROLLBACK_TAG="${CURRENT_IMAGE##*:}"
  export IMAGE_TAG="$ROLLBACK_TAG"

  echo "Pulling rollback image if needed..."
  docker compose -f "$COMPOSE_FILE" pull

  echo "Starting rollback containers..."
  docker compose -f "$COMPOSE_FILE" up -d

  echo "Waiting for rollback app to be ready..."

  for i in $(seq 1 "$HEALTH_RETRIES"); do
    if curl --fail --silent "$APP_URL"; then
      echo
      echo "Rollback health check passed."
      echo "Rollback completed successfully."
      exit 1
    fi

    echo "Rollback health check attempt $i/$HEALTH_RETRIES failed. Retrying in $HEALTH_DELAY seconds..."
    sleep "$HEALTH_DELAY"
  done

  echo "Rollback failed: previous image did not become healthy."
  exit 1
fi

echo "Rollback not possible: no previous image found."
exit 1
