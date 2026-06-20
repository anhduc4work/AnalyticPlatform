import os

# MCP configuration
MCP_DEV_USERNAME = os.environ.get("MCP_DEV_USERNAME", "admin")

# Public access — allow unauthenticated users to view published dashboards
PUBLIC_ROLE_LIKE = "Gamma"

# Enable embedding dashboards via iframe
FEATURE_FLAGS = {
    "EMBEDDABLE_CHARTS": True,
    "EMBEDDED_SUPERSET": True,
    "THUMBNAILS": True,
    "PLAYWRIGHT_REPORTS_AND_THUMBNAILS": True,
}

# Thumbnail configuration
from celery.schedules import crontab
THUMBNAIL_SELENIUM_USER = "admin"
WEBDRIVER_TYPE = "playwright"
WEBDRIVER_BASEURL = "http://localhost:8088/"
WEBDRIVER_BASEURL_USER_FRIENDLY = "http://localhost:8088/"

# Allow CORS for embedding
ENABLE_CORS = True
CORS_OPTIONS = {
    "supports_credentials": True,
    "allow_headers": ["*"],
    "resources": ["*"],
    "origins": ["*"],
}
