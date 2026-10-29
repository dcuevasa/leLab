#!/usr/bin/env bash
# =====================================================================
# Launch LeLab in Docker on the Lenovo ThinkStation PGX (Zero Host Installs)
#
# Usage:
#   ./leLab/run_docker.sh              # Start LeLab on port 8000 (foreground)
#   DETACH=1 ./leLab/run_docker.sh     # Start LeLab in background container "lelab"
#   ./leLab/run_docker.sh --rebuild    # Rebuild frontend/dist via node:22-alpine then start
#   ./leLab/run_docker.sh --stop       # Stop running "lelab" container
# =====================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESIS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
PORT="${PORT:-8000}"
NAME="${NAME:-lelab}"

REBUILD=0
PASSTHROUGH_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --rebuild)
      REBUILD=1
      ;;
    --stop)
      echo "Stopping container '$NAME' (if running)..."
      docker rm -f "$NAME" 2>/dev/null || true
      exit 0
      ;;
    *)
      PASSTHROUGH_ARGS+=("$arg")
      ;;
  esac
done

# Build frontend/dist inside node:22-alpine if missing or --rebuild requested
if [[ "$REBUILD" == "1" || ! -f "$FRONTEND_DIR/dist/index.html" ]]; then
  echo "=========================================================="
  echo " Building LeLab Frontend (frontend/dist) via node:22-alpine"
  echo "=========================================================="
  docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$FRONTEND_DIR":/app \
    -w /app \
    node:22-alpine \
    sh -c "npm ci && npm run build"
fi

# Stop any stale container with the same name
docker rm -f "$NAME" >/dev/null 2>&1 || true

PORT="$PORT" NAME="$NAME" LELAB_PORT="$PORT" \
  exec "$TESIS_DIR/pgx-training/docker/run.sh" \
  bash /workspace/pgx-training/experiments/00_run_lelab.sh "${PASSTHROUGH_ARGS[@]}"
