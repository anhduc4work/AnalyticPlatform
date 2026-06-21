#!/usr/bin/env bash
#
# setup.sh — One-command setup for the AnalyticPlatform stack
#
# Idempotent: safe to run multiple times.
# Handles paths with spaces (all paths are quoted).
#
set -euo pipefail

# ── Resolve project root (directory containing this script) ──────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
SUPERSET_DIR="$PROJECT_ROOT/superset"
MCP_DIR="$SUPERSET_DIR/superset-mcp"
PROXY_VENV="$SUPERSET_DIR/proxy-venv"
MCP_VENV="$MCP_DIR/.venv"

# ── Colours / helpers ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

info()  { printf "${GREEN}[INFO]${NC}  %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
die()   { error "$@"; exit 1; }

# ── 1. Check prerequisites ──────────────────────────────────────────────────
info "Checking prerequisites..."

command -v docker >/dev/null 2>&1   || die "docker is not installed."
docker compose version >/dev/null 2>&1 || die "docker compose (v2) is not available."
command -v python3 >/dev/null 2>&1  || die "python3 is not installed."

USE_UV=false
if command -v uv >/dev/null 2>&1; then
    USE_UV=true
    info "Using uv for virtual-environment management."
else
    info "uv not found; falling back to pip."
fi

info "All prerequisites satisfied."

# ── Helper: create venv + install deps ───────────────────────────────────────
create_venv() {
    local venv_path="$1"
    shift
    local deps=("$@")

    if [ -d "$venv_path" ] && [ -f "$venv_path/bin/python" ]; then
        info "Virtual environment already exists at $venv_path — skipping creation."
    else
        info "Creating virtual environment at $venv_path ..."
        if $USE_UV; then
            uv venv "$venv_path"
        else
            python3 -m venv "$venv_path"
        fi
    fi

    info "Installing dependencies into $venv_path ..."
    if $USE_UV; then
        uv pip install --python "$venv_path/bin/python" "${deps[@]}"
    else
        "$venv_path/bin/pip" install --upgrade pip >/dev/null 2>&1
        "$venv_path/bin/pip" install "${deps[@]}"
    fi
}

# ── 2. Install bintocher mcp-superset (137 tools) ──────────────────────────
info "Installing mcp-superset (bintocher)..."
if command -v mcp-superset >/dev/null 2>&1; then
    info "mcp-superset already installed."
else
    pip3 install --break-system-packages mcp-superset 2>/dev/null \
        || pip3 install mcp-superset 2>/dev/null \
        || die "Failed to install mcp-superset. Try: pip3 install mcp-superset"
fi

# ── 3. Proxy venv (for official MCP stdio bridge) ──────────────────────────
info "Setting up proxy venv..."
create_venv "$PROXY_VENV" fastmcp

# ── 4. Copy .env if missing ─────────────────────────────────────────────────
if [ -f "$SUPERSET_DIR/.env.example" ] && [ ! -f "$SUPERSET_DIR/.env" ]; then
    info "Creating superset/.env from .env.example ..."
    cp "$SUPERSET_DIR/.env.example" "$SUPERSET_DIR/.env"
    warn "Review superset/.env and change default values before going to production."
fi

# ── 5. Generate .mcp.json from template ────────────────────────────────────
if [ -f "$PROJECT_ROOT/.mcp.json.template" ]; then
    info "Generating .mcp.json from template..."
    sed "s|__PROJECT_DIR__|$PROJECT_ROOT|g" "$PROJECT_ROOT/.mcp.json.template" > "$PROJECT_ROOT/.mcp.json"
    info "Generated .mcp.json with project path: $PROJECT_ROOT"
fi

# ── 6. Build and start Docker containers ────────────────────────────────────
info "Building and starting Docker containers..."
docker compose -f "$SUPERSET_DIR/docker-compose.yml" up -d --build

# ── 6. Wait for Superset to be healthy ──────────────────────────────────────
info "Waiting for Superset to become healthy (this may take 1-3 minutes)..."

MAX_WAIT=300  # seconds
ELAPSED=0
INTERVAL=5

while true; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' superset 2>/dev/null || echo "not_found")
    if [ "$STATUS" = "healthy" ]; then
        info "Superset container is healthy."
        break
    fi

    if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
        die "Timed out after ${MAX_WAIT}s waiting for Superset to become healthy (current status: $STATUS)."
    fi

    printf "."
    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))
done
echo  # newline after dots

# ── 7. Initialise Superset (admin user, db upgrade, init) ───────────────────
info "Running Superset database migrations..."
docker exec superset superset db upgrade

info "Creating Superset admin user (idempotent — skips if exists)..."
docker exec superset superset fab create-admin \
    --username "${SUPERSET_ADMIN_USERNAME:-admin}" \
    --firstname Admin \
    --lastname User \
    --email "admin@superset.local" \
    --password "${SUPERSET_ADMIN_PASSWORD:-admin}" \
    || warn "Admin user may already exist — continuing."

info "Initialising Superset roles and permissions..."
docker exec superset superset init

# ── 8. Done ─────────────────────────────────────────────────────────────────
echo ""
info "============================================"
info "  AnalyticPlatform setup complete!"
info "============================================"
info ""
info "  Superset UI:   http://localhost:8088"
info "  MCP endpoint:  http://localhost:5008"
info ""
info "  Default login: admin / admin"
info "  (change in superset/.env)"
info ""
info "  To stop:   docker compose -f \"$SUPERSET_DIR/docker-compose.yml\" down"
info "  To reset:  docker compose -f \"$SUPERSET_DIR/docker-compose.yml\" down -v"
info ""
