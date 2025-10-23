#!/usr/bin/env bash
set -euo pipefail

NAME="${NAME:-myapp}"
BUILDER_IMAGE="${BUILDER_IMAGE:-builder:latest}"
IMAGE_TAG="${IMAGE_TAG:-${NAME}:latest}"
DOCKERFILE="${DOCKERFILE:-Dockerfile}"
CONTEXT="${CONTEXT:-.}"
PROXY_ARGS="${PROXY_ARGS:-}"

AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}"
AWS_REGION="${AWS_REGION:-}"
ECR_REPO="${ECR_REPO:-}"
ECR_PUSH="${ECR_PUSH:-false}"

PROXY_BUILD_ARGS=()
if [ -n "$PROXY_ARGS" ]; then
  for arg in $PROXY_ARGS; do
    PROXY_BUILD_ARGS+=( "--build-arg" "${arg#-e }" )
  done
fi

echo "=== Building image: ${IMAGE_TAG}"
docker build --force-rm=true -t "${IMAGE_TAG}" --build-arg NAME="${NAME}" --build-arg BUILDER_IMAGE="${BUILDER_IMAGE}" "${PROXY_BUILD_ARGS[@]}" -f "${DOCKERFILE}" "${CONTEXT}"

if [ "${ECR_PUSH}" = "true" ]; then
  if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ] || [ -z "$ECR_REPO" ]; then
    echo "ERROR: AWS_ACCOUNT_ID, AWS_REGION and ECR_REPO must be set to push to ECR"
    exit 1
  fi
  ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
  aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_URI}"
  TAG="${IMAGE_TAG##*:}"
  docker tag "${IMAGE_TAG}" "${ECR_URI}:${TAG}"
  docker push "${ECR_URI}:${TAG}"
  echo "✅ Image pushed: ${ECR_URI}:${TAG}"
else
  echo "✅ Image built (not pushed): ${IMAGE_TAG}"
fi
