#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ENV_FILE="$REPO_DIR/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  set +a
fi

IMAGE="claude-usage"
CONTAINER="${CONTAINER:-claude-usage}"
NETWORK="${NETWORK:-repowatch-shared}"
PORT="${PORT:-9898}"
CONTEXT_PATH="${CONTEXT_PATH:-}"
SCAN_INTERVAL_SECONDS="${SCAN_INTERVAL_SECONDS:-}"

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

# echo "⬇  Pulling latest..."
# cd "$REPO_DIR"
# git pull

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
if [ -n "$SCAN_INTERVAL_SECONDS" ]; then
  DOCKER_ARGS+=(-e "SCAN_INTERVAL_SECONDS=${SCAN_INTERVAL_SECONDS}")
fi
docker run "${DOCKER_ARGS[@]}" "$IMAGE"

DISPLAY_PATH="${CONTEXT_PATH:-}"
echo "✅  Running at http://localhost:${PORT}${DISPLAY_PATH}/"
