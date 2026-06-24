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

# CSP: allow unsafe-eval for Handlebars chart rendering
TALISMAN_ENABLED = False

# Branding
APP_NAME = "Plantex Analytics"

# Custom color scheme for charts
EXTRA_CATEGORICAL_COLOR_SCHEMES = [
    {
        "id": "plantex",
        "description": "Plantex brand colors",
        "label": "Plantex",
        "isDefault": True,
        "colors": [
            "#2563eb",  # Plantex blue
            "#10b981",  # Plantfruct green
            "#f59e0b",  # Amber
            "#8b5cf6",  # Purple
            "#ef4444",  # Red
            "#06b6d4",  # Cyan
            "#f97316",  # Orange
            "#6366f1",  # Indigo
            "#ec4899",  # Pink
            "#14b8a6",  # Teal
        ],
    }
]

# Theme — Plantex brand colors
THEME_OVERRIDES = {
    "colors": {
        "primary": {
            "base": "#2563eb",       # Plantex blue
            "dark1": "#1d4ed8",
            "dark2": "#1e40af",
            "light1": "#3b82f6",
            "light2": "#60a5fa",
            "light3": "#93bbfd",
            "light4": "#bfdbfe",
            "light5": "#dbeafe",
        },
        "secondary": {
            "base": "#10b981",       # Plantfruct green
            "dark1": "#059669",
            "dark2": "#047857",
            "dark3": "#065f46",
            "light1": "#34d399",
            "light2": "#6ee7b7",
            "light3": "#a7f3d0",
            "light4": "#d1fae5",
            "light5": "#ecfdf5",
        },
        "grayscale": {
            "base": "#64748b",       # Muted text
            "dark1": "#475569",
            "dark2": "#1e293b",      # Primary text
            "light1": "#94a3b8",
            "light2": "#cbd5e1",
            "light3": "#e2e8f0",     # Borders
            "light4": "#f1f5f9",     # Company row bg
            "light5": "#f8fafc",
        },
    },
    "typography": {
        "families": {
            "sansSerif": "'Inter', 'Helvetica', 'Arial', sans-serif",
            "serif": "'Georgia', 'Times New Roman', serif",
            "monospace": "'Fira Code', 'Courier New', monospace",
        },
    },
    "gridUnit": 4,
    "borderRadius": 6,
}

# Allow CORS for embedding
ENABLE_CORS = True
CORS_OPTIONS = {
    "supports_credentials": True,
    "allow_headers": ["*"],
    "resources": ["*"],
    "origins": ["*"],
}
