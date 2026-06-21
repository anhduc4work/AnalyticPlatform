# CLAUDE.md — AnalyticPlatform

## Superset Dashboard Management

### Ghost Chart Error ("no chart definition associated with this component")

When replacing or deleting a chart on a dashboard, you MUST update ALL THREE things in a single `superset_dashboard_update` call:

1. **`position_json`** — remove ALL references to the deleted chart ID, replace with new chart ID
2. **`json_metadata`** — update `chartsInScope` arrays in native filter config to reference the new chart ID instead of deleted one
3. **Chart association** — the official MCP's `add_chart_to_existing_dashboard` appends a NEW row instead of replacing. Do NOT use it for swaps. Instead, put the new chart ID directly in the position_json.

**Root cause:** Superset's dashboard stores chart references in THREE places (position_json, json_metadata filters, and the charts association list). If any one still references a deleted chart ID, you get the ghost error.

**Correct pattern for swapping chart X with chart Y:**
```
1. Create new chart Y (generate_chart with save_chart=true)
2. Delete old chart X (superset_chart_delete)
3. Single superset_dashboard_update call with BOTH:
   - position_json: replace all CHART-X references with CHART-Y
   - json_metadata: replace X with Y in all chartsInScope arrays
```

**Do NOT:**
- Delete a chart then update position_json in a separate call (race condition)
- Use `add_chart_to_existing_dashboard` to replace a chart (it appends, doesn't replace)
- Forget to update `chartsInScope` in the native filter configuration

### Creating a New Dashboard with Charts

NEVER use `superset_dashboard_create` (community) + `superset_dashboard_update` with position_json to build a dashboard. The charts won't be associated and you get ALL ghost charts.

**Correct pattern:**
```
1. Create all charts first (generate_chart with save_chart=true)
2. Use official MCP `generate_dashboard` with chart_ids=[...] — this creates the dashboard AND associates all charts in one call
3. THEN customize layout/filters via superset_dashboard_update (position_json + json_metadata)
```

The official `generate_dashboard` is the ONLY reliable way to create a dashboard with proper chart associations. Community `superset_dashboard_create` creates an empty shell — charts referenced in position_json won't render.

### Handlebars Charts and CSP

Handlebars chart type with inline `<style>` tags may trigger Content Security Policy (CSP) errors in Superset. The `unsafe-eval` directive is blocked by default. Workaround: use the `style_template` field in the handlebars config instead of inline `<style>` in the template, or add CSP exceptions to superset_config.py.

## Visual Validation (MANDATORY)

After building or modifying ANY dashboard, ALWAYS verify it visually using Playwright before presenting to the user. Never claim a dashboard is "done" without a screenshot.

**Steps:**
1. `browser_navigate` to `http://localhost:8088/login/`
2. `browser_fill_form` with username=admin, password=admin → submit
3. `browser_navigate` to the dashboard URL (`http://localhost:8088/superset/dashboard/{id}/`)
4. `browser_wait_for` the dashboard to fully load (wait for chart containers)
5. `browser_take_screenshot` to capture the full dashboard
6. `browser_snapshot` to get the accessibility tree — scan for error messages:
   - "no chart definition associated with this component" → ghost chart, fix position_json
   - "No data" → check dataset/SQL
   - "error" → check chart config
7. If errors found → fix → re-screenshot → verify clean
8. `browser_close` when done

**Why:** Dashboard APIs return success even when charts render incorrectly. Only a visual check catches layout issues, ghost charts, empty charts, and rendering errors. The user should never see a broken dashboard.

## Chart Styling Rules

When creating charts via `generate_chart`, follow these rules to prevent visual overlap and ensure readability:

### Axis Title vs Axis Label Overlap
Y-axis titles (e.g. "Revenue (USD)") overlap with axis tick labels (e.g. "$800,000") in Superset. There is no `nameGap` control via the API.

**Rule: Do NOT set `y_axis_title` when using currency or large number formats.** The metric label in the legend already conveys the same information. Setting both causes overlap.

When creating charts via `generate_chart`:
- Use `y_axis: {"format": "$,.0f"}` but do NOT set `y_axis: {"title": "..."}`
- The metric label (e.g. `"label": "Revenue (USD)"`) appears in the legend — that's sufficient
- If you must have an axis title, use abbreviated formats (`$~s` → "$800K") to keep labels short

### Axis Formatting Best Practices
| Data Range | Recommended Format | Renders As |
|-----------|-------------------|-----------|
| 0 - 999 | `,.0f` | 500 |
| 1K - 999K | `$,.0f` or `$~s` | $500,000 or $500K |
| 1M+ | `$,.2s` | $2.3M |
| Percentages | `.1%` | 45.2% |
| Decimals | `,.2f` | 1,234.56 |

### Number Formatting
All numbers must show 0-2 decimal places maximum. Never show raw floats like 728658.5757.

| Type | Format | Example |
|------|--------|---------|
| Currency (integer) | `$,.0f` | $728,659 |
| Currency (cents) | `$,.2f` | $728,658.58 |
| Percentage | `.1f` | 36.6 |
| Count/Integer | `,.0f` | 4,922 |
| Decimal | `,.2f` | 230.77 |

When creating charts, ALWAYS set explicit format strings. Never rely on defaults which show too many decimals.

### Avoid Handlebars Charts
Do NOT use Handlebars (`viz_type: "handlebars"`) chart type. It has multiple issues:
- CSP blocks inline `<style>` tags and `unsafe-eval`
- Custom helpers (`subtract`, `ifEquals`, `gt`) are not available in Superset
- Fragile and hard to debug
Use native Superset `table` or `pivot_table_v2` instead.

### Other Visual Rules
- **Bar chart labels**: Don't enable data labels on bars when there are many categories — they overlap
- **Pie chart**: Max 6 slices. Beyond that, use a bar chart instead
- **Legend**: Position `top` or `right`. Never let it overlap chart area
- **Chart height in dashboard**: KPIs = 25-30, trend lines = 45-50, comparison charts = 40, tables/pivots = 50-60

## MCP Servers

Two MCP servers. Priority: Official > bintocher.

### superset-official (Apache built-in)
- High-level tools: `generate_chart`, `generate_dashboard`, `create_virtual_dataset`, `get_chart_type_schema`
- Tools use `request` wrapper: `{"request": {"dataset_id": 3, ...}}`
- `generate_chart` requires `config` field matching the chart type schema
- Always call `get_chart_type_schema` before creating charts
- `generate_dashboard` is the ONLY reliable way to create dashboards with chart associations

### superset (bintocher/mcp-superset)
- 137 tools: full CRUD, security/RBAC, native filters, export/import, reports
- Installed via `pip install mcp-superset`, runs as `mcp-superset --transport stdio`
- Auto-authenticates via env vars `SUPERSET_USERNAME`/`SUPERSET_PASSWORD`
- Use for: dashboard updates (position_json, json_metadata), database CRUD, SQL Lab, security, filters, export/import
- Tool names: `superset_dashboard_*`, `superset_chart_*`, `superset_database_*`, `superset_sqllab_*`, etc.

### When to use which
| Task | Use |
|------|-----|
| Create chart | Official `generate_chart` |
| Create dashboard | Official `generate_dashboard` |
| Create virtual dataset | Official `create_virtual_dataset` |
| Get chart type schema | Official `get_chart_type_schema` |
| Update dashboard layout/filters | bintocher `superset_dashboard_update` |
| Update chart params | bintocher `superset_chart_update` |
| Database CRUD | bintocher `superset_database_*` |
| SQL execution | bintocher `superset_sqllab_execute` |
| Security/RBAC | bintocher `superset_user_*`, `superset_role_*` |
| Native filter CRUD | bintocher `superset_dashboard_filter_*` |
| Export/Import | bintocher `superset_dashboard_export/import` |

## Analytics Framework

All dashboards must follow the standards in `docs/ANALYTICS_FRAMEWORK.md`:
- **CRISP-DM** for process stages
- **IBCS SUCCESS** for chart design (SAY, UNIFY, CONDENSE, CHECK, EXPRESS, SIMPLIFY, STRUCTURE)
- **Gestalt Principles** for layout (Proximity, Similarity, Continuity)
- **Information Hierarchy**: KPIs → Trends → Comparisons → Detail (top to bottom)
- **Chart type selection**: based on data pattern, not preference (see decision matrix in framework doc)
- **Dashboard type**: determined by audience input (executive→strategic, manager→tactical, operator→operational, analyst→analytical)

## Project Path

Path has a space (`Git Repo`). MCP server configs use bash wrapper scripts (`start-community-mcp.sh`, `start-official-mcp.sh`) instead of direct python commands.
