#!/bin/bash
# Start the MCP server in the background
/app/.venv/bin/superset mcp run --host 0.0.0.0 --port 5008 &

# Run the original CMD
exec /app/docker/entrypoints/run-server.sh "$@"
