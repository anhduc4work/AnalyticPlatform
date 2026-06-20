---
name: analytics-build
description: "Use after analytics-design is approved or when user wants to create charts and assemble a dashboard in Superset. Creates all charts, assembles dashboard with layout, configures native filters, and generates project documentation as .docx."
user-invocable: true
---

# Analytics Build — Dashboard Construction

This skill creates all charts, assembles the dashboard, configures filters, and generates project documentation. It executes the approved design spec from the analytics-design phase. Reference `CLAUDE.md` for ghost chart error prevention and other critical implementation details.

**Only proceed if the user has explicitly approved the design from the analytics-design phase.**

## Prerequisites

- Approved design spec from `projects/{project_slug}/design_spec.md`.
- EDA profile from `projects/{project_slug}/eda_profile.md`.
- Registered datasets in Superset (from EDA phase).
- Authentication token from earlier phases (or re-authenticate).
- Write build log to `projects/{project_slug}/build_log.md`.
- Save .docx output to `projects/{project_slug}/output/`.

## Procedure

### Step 1: Verify Approval

Confirm the user has approved the design. If there is any ambiguity, ask: "Has the dashboard design been approved? Should I proceed to build?"

Do NOT build without explicit approval.

### Step 2: Create Virtual Datasets (if needed)

For any virtual datasets planned during the design phase:

1. Call `superset_dataset_create` with the SQL query as a virtual dataset (or use `create_virtual_dataset` if available via the official MCP).
2. Record the returned `dataset_id` for use in chart creation.

### Step 3: Create Charts

For each chart in the approved design, follow this process:

#### 3a. Get Chart Type Schema

Before creating any chart, call `get_chart_type_schema` (official MCP) to retrieve the valid configuration schema for that `viz_type`. This ensures you use correct parameter names and structures.

#### 3b. Create the Chart

Use the official MCP `generate_chart` tool with `save_chart=true`:

- Wrap the parameters in a `{"request": {...}}` wrapper as required by the official MCP.
- Include:
  - `viz_type`: From the design spec.
  - `datasource_id`: The dataset ID.
  - `datasource_type`: Typically `"table"`.
  - Chart-specific configuration (metrics, dimensions, filters, colors, etc.) as defined by the schema from Step 3a.

**Fallback**: If the official MCP `generate_chart` call fails, fall back to `superset_chart_create` (community MCP) with equivalent parameters.

#### 3c. Record Chart IDs

Capture the returned `chart_id` (or `slice_id`) for each successfully created chart. You will need these for dashboard assembly.

### Step 4: Assemble the Dashboard

#### 4a. Create the Dashboard

Use the official MCP `generate_dashboard` to create the dashboard shell, or use `superset_dashboard_create` (community) with:
- `dashboard_title`: From the design spec.
- `slug`: A URL-friendly version of the title.

Record the `dashboard_id`.

#### 4b. Update Layout with position_json

Call `superset_dashboard_update` to set the dashboard layout via `position_json`.

The `position_json` defines a grid-based layout. Each chart is placed in a `CHART-` element within `ROW-` containers. The grid is 12 columns wide.

Example structure:
```json
{
  "DASHBOARD_VERSION_KEY": "v2",
  "ROOT_ID": {"type": "ROOT", "id": "ROOT_ID", "children": ["GRID_ID"]},
  "GRID_ID": {"type": "GRID", "id": "GRID_ID", "children": ["ROW-1", "ROW-2", "ROW-3"], "parents": ["ROOT_ID"]},
  "HEADER_ID": {"type": "HEADER", "id": "HEADER_ID", "meta": {"text": "Dashboard Title"}},
  "ROW-1": {
    "type": "ROW", "id": "ROW-1",
    "children": ["CHART-1", "CHART-2", "CHART-3"],
    "parents": ["ROOT_ID", "GRID_ID"],
    "meta": {"background": "BACKGROUND_TRANSPARENT"}
  },
  "CHART-1": {
    "type": "CHART", "id": "CHART-1",
    "children": [],
    "parents": ["ROOT_ID", "GRID_ID", "ROW-1"],
    "meta": {
      "width": 4, "height": 12,
      "chartId": <actual_chart_id>,
      "sliceName": "Chart Title",
      "uuid": "<generated_uuid>"
    }
  }
}
```

Layout rules from the design phase:
- **Row 1 (KPIs)**: Each big number gets `width: 3` or `width: 4` (3-4 across in 12-col grid), `height: 10-12`.
- **Row 2 (Trend)**: Full-width chart, `width: 12`, `height: 16-20`.
- **Row 3 (Comparisons)**: 2-3 charts at `width: 6` or `width: 4`, `height: 16-20`.
- **Row 4+ (Details)**: Full-width tables, `width: 12`, `height: 20-24`.

#### 4c. CRITICAL — Prevent Ghost Charts

**Reference `CLAUDE.md` for the ghost chart error.**

When updating `position_json`, you MUST also update `json_metadata` in the SAME `superset_dashboard_update` call. Specifically, the `chartsInScope` array in `json_metadata` must exactly match the set of `chartId` values in `position_json`.

If you swap or delete a chart:
1. Remove the old chart from `position_json`.
2. Remove the old chart ID from `json_metadata.chartsInScope`.
3. Add the new chart to `position_json`.
4. Add the new chart ID to `json_metadata.chartsInScope`.
5. Send BOTH `position_json` and `json_metadata` in a SINGLE `superset_dashboard_update` call.

Failure to do this causes "ghost charts" — phantom chart placeholders that appear on the dashboard but render nothing.

### Step 5: Configure Native Filters

Update `json_metadata` to include native filters:

```json
{
  "native_filter_configuration": [
    {
      "id": "FILTER-1",
      "name": "Region",
      "filterType": "filter_select",
      "targets": [{"datasetId": <dataset_id>, "column": {"name": "region"}}],
      "defaultDataMask": {},
      "cascadeParentIds": [],
      "scope": {"rootPath": ["ROOT_ID"], "excluded": []},
      "controlValues": {
        "enableEmptyFilter": false,
        "defaultToFirstItem": false,
        "multiSelect": true,
        "searchAllOptions": false,
        "inverseSelection": false
      }
    },
    {
      "id": "FILTER-TIME",
      "name": "Date Range",
      "filterType": "filter_time",
      "targets": [{"datasetId": <dataset_id>, "column": {"name": "order_date"}}],
      "defaultDataMask": {},
      "scope": {"rootPath": ["ROOT_ID"], "excluded": []}
    }
  ],
  "chart_configuration": {},
  "cross_filters_enabled": true
}
```

**Important**: Include this in the same `json_metadata` that contains `chartsInScope` to avoid overwriting. Merge all `json_metadata` fields and send in one update.

### Step 6: Enable Cross-Filtering

Set `"cross_filters_enabled": true` in `json_metadata` (included in Step 5 above).

This allows users to click on a bar segment or pie slice to filter the entire dashboard.

### Step 7: Rename Charts with Clean Titles

For each chart, call `superset_chart_update` to set a clean, descriptive title following IBCS SAY rules:
- State the message, not just the metric name.
- Example: "Monthly Revenue Trend (Last 12 Months)" instead of "Revenue Line Chart".
- Keep titles concise but informative.

### Step 8: Visual Verification with Playwright

Before presenting to the user, verify the dashboard visually using the Playwright MCP:

1. **Navigate** to the dashboard URL:
   - `browser_navigate` to `http://localhost:8088/login/` first
   - `browser_fill_form` with username=admin, password=admin, then submit
   - `browser_navigate` to `http://localhost:8088/superset/dashboard/{dashboard_id}/`
   - Wait for the dashboard to load: `browser_wait_for` selector `.dashboard-component` or similar

2. **Take a screenshot** of the full dashboard:
   - `browser_take_screenshot` to capture the rendered state

3. **Check for errors** by inspecting the page:
   - `browser_snapshot` to get the accessibility tree
   - Look for error messages: "There is no chart definition", "error", "No data", broken chart placeholders
   - Check that all expected chart titles appear in the snapshot

4. **Self-heal if errors found:**
   - If ghost chart error → fix position_json + json_metadata (see CLAUDE.md), re-screenshot
   - If "No data" → check dataset SQL query, verify column names match
   - If chart missing → verify chart_id exists, re-add to dashboard
   - If layout broken → adjust position_json widths/heights

5. **Close browser** when done: `browser_close`

Only proceed to present to user after the screenshot shows no errors.

### Step 9: Present Dashboard for Visual Review (HITL Gate 2)

Present the dashboard URL AND the screenshot to the user:

```
## Dashboard Built Successfully

### Dashboard
- Title: [title]
- URL: [Superset dashboard URL]
- Charts Created: [N]

### Charts
| # | Title | Type | Status |
|---|---|---|---|
| 1 | Total Revenue | Big Number | Created |
| 2 | Revenue Trend | Line | Created |
| ... | ... | ... | ... |

### Filters Configured
- [list of filters]
- Cross-filtering: Enabled

---
**Please open the dashboard URL and review the visual output.**
- Are the charts rendering correctly?
- Is the layout appropriate?
- Do any charts need adjustment?

Once you approve, I will generate the project documentation (.docx).
```

Wait for user feedback. If the user requests changes:
- Modify specific charts via `superset_chart_update`.
- Adjust layout via `superset_dashboard_update` (always updating BOTH `position_json` and `json_metadata` together).
- Re-present for approval.

### Step 10: Generate Project Documentation

After the user approves the final dashboard:

1. Call `superset_export_project_document` to generate a `.docx` file documenting the project.
2. The document should capture:
   - Business context (from intake).
   - Data sources and schema (from EDA).
   - Dashboard design rationale (from design).
   - Chart specifications and configurations.
   - Data quality notes and caveats.
3. Present the document path/download link to the user.

## Important Notes

- Always create charts BEFORE assembling the dashboard — you need the chart IDs for the layout.
- If a chart creation fails, log the error, attempt the fallback method, and if both fail, inform the user which chart could not be created and why.
- The ghost chart error is the most common build issue. Always update `position_json` and `json_metadata` together in a single call.
- Generate UUIDs for chart elements in `position_json` — do not reuse UUIDs across elements.
- Test that the dashboard URL is accessible before presenting it to the user.
- If the user wants to iterate on the dashboard after initial build, each modification cycle should follow the same pattern: modify, update both `position_json` and `json_metadata`, present for review.
