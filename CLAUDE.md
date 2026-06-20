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

## MCP Servers

- Community MCP auth: call `superset_auth_authenticate_user` at session start
- Official MCP tools use `request` wrapper: `{"request": {"dataset_id": 3, ...}}`
- Official MCP `generate_chart` requires `config` field matching the chart type schema
- Use `get_chart_type_schema` to get valid config shapes before creating charts

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
