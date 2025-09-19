#!/bin/bash
# Minimal script: tag an existing local image as :latest and push to fixed ACR
# Usage:
#   ./push-image-to-acr.sh gtfs-validator
# If target-repo omitted, uses localImage name.
# ACR fixed to: dataplatform1commcrfabricaz2

set -euo pipefail
ACR_NAME="dataplatform1commcrfabricaz2"

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 localImage[:tag] [target-repo]" >&2
  exit 1
fi

INPUT_REF="$1"
TARGET_REPO="${2:-}" # optional override

# Split image and tag
IMAGE_NAME="${INPUT_REF%%:*}"
if [[ "$INPUT_REF" == *":"* ]]; then
  IMAGE_TAG="${INPUT_REF##*:}"
else
  IMAGE_TAG="latest"
fi

[[ -z "$TARGET_REPO" ]] && TARGET_REPO="$IMAGE_NAME"
REGISTRY_REF="$ACR_NAME.azurecr.io/$TARGET_REPO:latest"

# Checks
command -v az >/dev/null 2>&1 || { echo "Azure CLI not found" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker not found" >&2; exit 1; }

az account show >/dev/null 2>&1 || { echo "Not logged into Azure (run az login)" >&2; exit 1; }
az acr show -n "$ACR_NAME" >/dev/null 2>&1 || { echo "ACR not accessible: $ACR_NAME" >&2; exit 1; }

# Ensure local image exists
docker image inspect "$IMAGE_NAME:$IMAGE_TAG" >/dev/null 2>&1 || { echo "Local image not found: $IMAGE_NAME:$IMAGE_TAG" >&2; exit 1; }

# Login (quiet)
az acr login -n "$ACR_NAME" >/dev/null

echo "Tagging $IMAGE_NAME:$IMAGE_TAG -> $REGISTRY_REF"
docker tag "$IMAGE_NAME:$IMAGE_TAG" "$REGISTRY_REF"

echo "Pushing $REGISTRY_REF"
docker push "$REGISTRY_REF"

echo "Done: $REGISTRY_REF"