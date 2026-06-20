#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
exec proxy-venv/bin/python3 superset-official-mcp-proxy.py "$@"
