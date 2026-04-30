#!/bin/bash
set -e

DOCKERHUB_IMAGE="iacobstev/maintenance-tracker-app"
K8S_DEPLOYMENT="maintenance-tracker-app"
K8S_NAMESPACE="default"
NODEPORT_URL="http://localhost:31585/health"
HEALTH_RETRIES=10
HEALTH_DELAY=3

if [ -z "$1" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

TAG="$1"
IMAGE_TAG="$DOCKERHUB_IMAGE:$TAG"

echo "Deploying image to Kubernetes: $IMAGE_TAG"

CURRENT_IMAGE=$(kubectl get deployment "$K8S_DEPLOYMENT" \
  -n "$K8S_NAMESPACE" \
  -o jsonpath='{.spec.template.spec.containers[0].image}')

echo "Current image: $CURRENT_IMAGE"
echo "Target image: $IMAGE_TAG"

if [ "$CURRENT_IMAGE" == "$IMAGE_TAG" ]; then
  echo "Image is already deployed. Skipping rollout."
  exit 0
fi

kubectl set image deployment/"$K8S_DEPLOYMENT" \
  app="$IMAGE_TAG" \
  -n "$K8S_NAMESPACE"

echo "Waiting for rollout..."
if ! kubectl rollout status deployment/"$K8S_DEPLOYMENT" -n "$K8S_NAMESPACE"; then
  echo "Rollout failed. Rolling back..."
  kubectl rollout undo deployment/"$K8S_DEPLOYMENT" -n "$K8S_NAMESPACE"
  kubectl rollout status deployment/"$K8S_DEPLOYMENT" -n "$K8S_NAMESPACE"
  echo "Rollback completed."
  exit 1
fi

echo "Checking deployed image..."
kubectl get deployment "$K8S_DEPLOYMENT" \
  -n "$K8S_NAMESPACE" \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

echo "Running health check with retry..."
for i in $(seq 1 "$HEALTH_RETRIES"); do
  if curl --fail --silent "$NODEPORT_URL"; then
    echo
    echo "Health check passed."
    echo "CD deployment completed successfully."
    exit 0
  fi

  echo "Health check attempt $i/$HEALTH_RETRIES failed. Retrying in $HEALTH_DELAY seconds..."
  sleep "$HEALTH_DELAY"
done

echo "Health check failed after rollout. Rolling back..."
kubectl rollout undo deployment/"$K8S_DEPLOYMENT" -n "$K8S_NAMESPACE"
kubectl rollout status deployment/"$K8S_DEPLOYMENT" -n "$K8S_NAMESPACE"
echo "Rollback completed due to failed health check."
exit 1
