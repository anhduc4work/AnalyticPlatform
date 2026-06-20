import os

# MCP configuration
MCP_DEV_USERNAME = os.environ.get("MCP_DEV_USERNAME", "admin")

# Public access — allow unauthenticated users to view published dashboards
PUBLIC_ROLE_LIKE = "Gamma"

# Enable embedding dashboards via iframe
FEATURE_FLAGS = {
    "EMBEDDABLE_CHARTS": True,
    "EMBEDDED_SUPERSET": True,
}

# Allow CORS for embedding
ENABLE_CORS = True
CORS_OPTIONS = {
    "supports_credentials": True,
    "allow_headers": ["*"],
    "resources": ["*"],
    "origins": ["*"],
}
