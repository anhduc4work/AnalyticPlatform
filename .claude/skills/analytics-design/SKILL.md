---
name: analytics-design
description: "Use after analytics-eda or when user wants to design a dashboard layout. Maps analytical questions to chart types using IBCS standards, plans layout using Gestalt principles, configures filters. Produces a dashboard design spec for user approval before building."
user-invocable: true
---

# Analytics Design — Dashboard Planning

This skill maps analytical questions to chart types, plans the dashboard layout, and produces a design specification for user approval. It follows IBCS SUCCESS rules for chart standards and Gestalt principles for layout. Reference `docs/ANALYTICS_FRAMEWORK.md` for the full methodology.

**This is a HITL (human-in-the-loop) gate. Do NOT proceed to building until the user explicitly approves the design.**

## Prerequisites

- Analytical questions from intake (refined if needed).
- EDA profile: column classifications, detected relationships, registered dataset IDs, data quality flags.
- If running standalone, you need at minimum a list of questions and knowledge of the available data.

## Procedure

### Step 1: Determine Dashboard Type

Based on the audience collected during intake, classify the dashboard:

| Audience | Dashboard Type | Characteristics |
|---|---|---|
| C-suite, executives, board | **Strategic** | High-level KPIs, trends, minimal detail, big numbers prominent |
| Directors, managers | **Tactical** | Comparison charts, period-over-period, drill-down capability |
| Team leads, supervisors | **Operational** | Real-time or near-real-time, status indicators, action-oriented |
| Analysts, data scientists | **Analytical** | Detail-heavy, pivot tables, multiple dimensions, exploration-friendly |

The dashboard type influences chart selection, layout density, and complexity.

### Step 2: Map Questions to Charts

For each analytical question, select the appropriate chart type using this decision matrix:

| Question Pattern | Chart Type | Superset viz_type | Notes |
|---|---|---|---|
| "What is the total/current X?" | KPI / Big Number | `big_number_total` | Single aggregate metric |
| "How is X trending/changing over time?" | Line Chart | `echarts_timeseries_line` | Requires temporal column |
| "Compare X across Y categories" | Bar Chart | `echarts_bar` | Horizontal for many categories |
| "What percentage/proportion of total?" | Pie / Donut | `pie` | Use only for 2-6 slices; avoid for more |
| "Break down by multiple dimensions" | Pivot Table | `pivot_table_v2` | Or `handlebars` for custom formatting |
| "Show correlation between X and Y" | Scatter Plot | `echarts_scatter` | Two numeric measures required |
| "Show detail/list records" | Table | `table` | Sortable, paginated |
| "What is the distribution of X?" | Histogram | `histogram` | Single numeric column |
| "Show geographic patterns" | Map | `deck_scatter` or `country_map` | Requires geo data |
| "Show part-to-whole over time" | Area Chart | `echarts_timeseries_stacked` | Stacked area |
| "Show flow/funnel progression" | Funnel | `funnel` | Sequential stages |

**Rules:**
- If a question requires data from multiple tables, plan a virtual dataset using a SQL join query. Note this for the build phase — use `create_virtual_dataset` or `superset_dataset_create` with a SQL expression.
- Prefer bar charts over pie charts when categories exceed 6.
- Every KPI big number should show comparison (e.g., vs. previous period) if temporal data is available.
- Avoid redundant charts — if two questions are answered by the same chart, combine them.

### Step 3: Plan Virtual Datasets

For questions that require joining multiple tables:

1. Identify which tables need joining based on detected relationships from EDA.
2. Write the SQL query for the virtual dataset.
3. Note the dataset for creation during the build phase.

Format:
```
Virtual Dataset: [descriptive_name]
SQL: SELECT ... FROM table_a JOIN table_b ON table_a.fk = table_b.pk WHERE ...
Purpose: Answers question(s) #X, #Y
```

### Step 4: Plan Layout

Follow IBCS STRUCTURE standards and Gestalt principles for the layout:

#### Layout Template

```
+--------------------------------------------------+
| Row 1: KPI Big Numbers (3-5 across)              |
| [KPI 1]  [KPI 2]  [KPI 3]  [KPI 4]             |
+--------------------------------------------------+
| Row 2: Primary Time-Series Trend (full width)    |
| [Line/Area Chart — main trend question]          |
+--------------------------------------------------+
| Row 3: Comparison Charts (2-3 columns)           |
| [Bar Chart]         [Bar/Pie Chart]              |
+--------------------------------------------------+
| Row 4+: Detail Tables/Matrices (full width)      |
| [Pivot Table or Detail Table]                    |
+--------------------------------------------------+
```

#### Layout Rules

- **Gestalt Proximity**: Group related charts together. KPIs in one row, trends in another.
- **Gestalt Similarity**: Use consistent colors and styling for related metrics.
- **Visual hierarchy**: Most important information (KPIs) at the top, details at the bottom.
- **F-pattern reading**: Place the most critical chart at the top-left.
- **Full-width for time series**: Trend lines benefit from horizontal space.
- **2-3 column grid for comparisons**: Side-by-side comparison charts.
- **Full-width for tables**: Detail tables need horizontal space for columns.

#### IBCS SUCCESS Rules Application

- **S — Say**: Every chart must have a clear, descriptive title that states the message (e.g., "Monthly Revenue is Growing 12% YoY" not just "Revenue").
- **U — Unify**: Use consistent notation, scaling, and color across all charts.
- **C — Condense**: Maximize data-ink ratio. Remove unnecessary gridlines, borders, and decoration.
- **C — Check**: Ensure data integrity — no misleading axes, truncated scales, or distorted proportions.
- **E — Express**: Choose the right chart type for the data (as per the decision matrix above).
- **S — Simplify**: Avoid clutter. One message per chart.
- **S — Structure**: Organize information logically (KPIs → trends → comparisons → details).

### Step 5: Plan Filter Bar

Select columns for the native filter bar:

1. **Categorical columns** with 2-50 distinct values (from EDA classification) are filter candidates.
2. **Time range filter**: Always include if a temporal column exists.
3. **Cross-filter**: Enable cross-filtering so clicking a bar/slice filters the entire dashboard.

Prioritize filters that:
- Align with the user's stated filter preferences (from intake).
- Represent key business dimensions (e.g., region, product category, department).
- Have reasonable cardinality (not too many, not too few values).

### Step 6: Apply Chart Cap

Respect the `max_charts` preference from intake:
- If total planned charts exceeds `max_charts`, prioritize by: KPIs first, then the chart most directly answering each question, then supporting charts.
- Inform the user which charts were cut and why.
- Suggest that cut charts could be added to a secondary dashboard.

### Step 7: Present Design Spec for Approval

Present the complete design to the user in this format:

```
## Dashboard Design Spec

### Overview
- Title: [dashboard title]
- Type: [Strategic/Tactical/Operational/Analytical]
- Audience: [audience]
- Total Charts: [N]

### Charts

| # | Title | Type | viz_type | Dataset | Question Answered |
|---|---|---|---|---|---|
| 1 | Total Revenue | Big Number | big_number_total | orders | "What is total revenue?" |
| 2 | Revenue Trend | Line | echarts_timeseries_line | orders | "How is revenue trending?" |
| ... | ... | ... | ... | ... | ... |

### Virtual Datasets Required
- [name]: [SQL summary] — for chart(s) #X

### Layout Plan
[ASCII layout diagram as in Step 4]

### Filter Bar
- [Filter 1]: [column] from [table] ([N] distinct values)
- [Filter 2]: Time range on [column]
- Cross-filtering: Enabled

### Data Quality Notes
- [Any relevant quality flags that affect chart design]

---
**Please review and approve this design before I proceed to build.**
Do you want to modify any charts, change the layout, or adjust filters?
```

## Important Notes

- This is a HITL gate. Wait for explicit user approval (e.g., "looks good", "approved", "go ahead") before suggesting `/analytics-build`.
- If the user requests changes, update the design and re-present for approval.
- If questions from intake are vague, refine them based on EDA findings. For example, if the user asked "show me sales data" and EDA revealed columns like `revenue`, `units_sold`, `order_date`, `region`, suggest specific questions like "How is revenue trending monthly?" and "Which region has the highest sales?"
- Document any assumptions made during chart selection.
- If the data does not support a requested question (e.g., no temporal column for a trend), explain this to the user and suggest alternatives.
