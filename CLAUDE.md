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
