#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="claude-usage"
CONTAINER="claude-usage"
NETWORK="repowatch-shared"
PORT=9898
CONTEXT_PATH="${CONTEXT_PATH:-}"

echo "▶  Checking for running container..."
if docker ps -q --filter "name=^${CONTAINER}$" | grep -q .; then
  echo "⏹  Stopping ${CONTAINER}..."
  docker stop "$CONTAINER"
fi

echo "🔗  Ensuring isolated network..."
if ! docker network inspect "$NETWORK" &>/dev/null; then
  docker network create \
    --opt com.docker.network.bridge.enable_ip_masquerade=false \
    "$NETWORK"
fi

echo "⬇  Pulling latest..."
cd "$REPO_DIR"
git pull

echo "🔨  Building image..."
docker build -t "$IMAGE" .

echo "🚀  Starting container..."
DOCKER_ARGS=(
  --rm -d
  --name "$CONTAINER"
  --network "$NETWORK"
  -p "$PORT:8080"
  -v "$HOME/.claude:/root/.claude:ro"
  -v "${CONTAINER}-data:/data"
  -e HOST=0.0.0.0
)
if [ -n "$CONTEXT_PATH" ]; then
  DOCKER_ARGS+=(-e "CONTEXT_PATH=${CONTEXT_PATH}")
fi
docker run "${DOCKER_ARGS[@]}" "$IMAGE"

DISPLAY_PATH="${CONTEXT_PATH:-}"
echo "✅  Running at http://localhost:${PORT}${DISPLAY_PATH}/"
