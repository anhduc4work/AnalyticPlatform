#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/superset-mcp"
exec .venv/bin/python3 main.py "$@"
