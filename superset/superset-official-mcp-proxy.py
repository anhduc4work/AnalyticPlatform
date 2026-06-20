"""
Stdio proxy for the official Superset MCP server running in Docker.
Connects to the HTTP endpoint at localhost:5008/mcp and bridges to stdio for Claude Code.
"""
import sys
import signal
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger(__name__)


def signal_handler(signum, frame):
    logger.info("Received signal %s, shutting down...", signum)
    sys.exit(0)


def main():
    from fastmcp import FastMCP

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    logger.info("Starting proxy to Superset official MCP at http://localhost:5008/mcp")
    proxy = FastMCP.as_proxy("http://localhost:5008/mcp/", name="Superset Official MCP")
    proxy.run()


if __name__ == "__main__":
    main()
