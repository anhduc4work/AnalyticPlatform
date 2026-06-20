# AnalyticPlatform

AI-powered analytics platform. One command to set up Apache Superset + MCP tools + Claude Code skills for end-to-end dashboard projects.

```
You describe what you need → Agent profiles data → designs dashboard → builds it → exports .docx report
```

## Quick Start

```bash
git clone https://github.com/anhduc4work/AnalyticPlatform.git
cd AnalyticPlatform
git submodule update --init --recursive
chmod +x setup.sh
./setup.sh
```

Then open Claude Code in this directory:
```bash
claude
```

Say: `/analytics-intake` to start your first analytics project.

## What You Get

| Component | Description |
|-----------|-------------|
| **Superset** | Apache Superset (Docker) at http://localhost:8088 |
| **MCP Servers** | 2 Superset MCP servers (60+ tools) for Claude Code |
| **4 Analytics Skills** | `/analytics-intake`, `/analytics-eda`, `/analytics-design`, `/analytics-build` |
| **IBCS Framework** | Dashboard design follows International Business Communication Standards |
| **Document Export** | Generate .docx project report (8 chapters, CRISP-DM aligned) |
| **Visual Verification** | Playwright auto-screenshots dashboards to catch errors |

## Skills (Slash Commands)

| Skill | When to Use |
|-------|-------------|
| `/analytics-intake` | Start a new project — collects data source, business context, questions |
| `/analytics-eda` | Profile data — schema discovery, column stats, quality flags |
| `/analytics-design` | Design dashboard — maps questions to charts, plans layout (HITL approval) |
| `/analytics-build` | Build dashboard — creates charts, assembles layout, exports .docx (HITL approval) |

## Pipeline

Follows **CRISP-DM** methodology with **IBCS SUCCESS** design standards.

```
INTAKE → EDA → DESIGN → [User Approval] → BUILD → [Visual Review] → REPORT
  │        │       │                          │           │              │
  Ch 1-2   Ch 3    Ch 4-5                    Ch 6        Playwright     Ch 7-8
                                                         screenshot
                                              ↓
                                    Single .docx with all 8 chapters
```

### Document Chapters (exported as .docx)

| # | Chapter | CRISP-DM Phase |
|---|---------|----------------|
| 1 | Project Charter | Business Understanding |
| 2 | Requirements Specification | Business Understanding |
| 3 | Data Assessment Report | Data Understanding |
| 4 | Data Dictionary | Data Preparation |
| 5 | Dashboard Design Specification | Modeling |
| 6 | UAT Test Plan | Evaluation |
| 7 | User Guide | Deployment |
| 8 | Handoff & Go-Live Report | Deployment |

## Architecture

```
AnalyticPlatform/
├── setup.sh                        # One-command setup
├── CLAUDE.md                       # Agent instructions & gotchas
├── .mcp.json.template              # MCP config (portable)
├── .claude/
│   └── skills/
│       ├── analytics-intake/       # Skill: collect inputs
│       ├── analytics-eda/          # Skill: data profiling
│       ├── analytics-design/       # Skill: dashboard design
│       └── analytics-build/        # Skill: build + export
├── docs/
│   └── ANALYTICS_FRAMEWORK.md     # Methodology reference (CRISP-DM, IBCS, Gestalt)
└── superset/
    ├── docker-compose.yml          # Superset + PostgreSQL + Redis
    ├── Dockerfile.superset         # Custom image (fastmcp + psycopg2)
    ├── superset-entrypoint.sh      # Starts MCP server + Superset
    ├── superset_config.py          # Superset config (MCP auth, CORS, embedding)
    ├── superset-official-mcp-proxy.py  # Stdio proxy for official MCP
    ├── start-community-mcp.sh      # Wrapper for community MCP
    ├── start-official-mcp.sh       # Wrapper for official MCP
    └── superset-mcp/               # Community MCP server (git submodule)
```

## Standards & Methodology

| Standard | What | Role in Pipeline |
|----------|------|-----------------|
| **CRISP-DM** | Process methodology | Stages and document structure |
| **IBCS SUCCESS** | Dashboard design | Chart selection, layout, notation |
| **Gestalt Principles** | Visual perception | Layout grouping, hierarchy |

See [docs/ANALYTICS_FRAMEWORK.md](docs/ANALYTICS_FRAMEWORK.md) for the full reference.

## Prerequisites

- Docker & Docker Compose
- Python 3.12+
- [uv](https://github.com/astral-sh/uv) (recommended) or pip
- [Claude Code](https://claude.ai/code) CLI

## Configuration

After `setup.sh`, the `.mcp.json` is auto-generated from `.mcp.json.template`. Superset defaults:

| Setting | Default | Change in |
|---------|---------|-----------|
| Admin user | admin / admin | `superset/.env` |
| Superset UI | http://localhost:8088 | `docker-compose.yml` |
| MCP endpoint | http://localhost:5008 | `docker-compose.yml` |

## Cross-Agent Compatibility

Skills follow the [Agent Skills open standard](https://agentskills.io) (SKILL.md format). Compatible with:
- Claude Code
- GitHub Copilot
- Cursor
- Gemini CLI (planned)

## License

MIT
