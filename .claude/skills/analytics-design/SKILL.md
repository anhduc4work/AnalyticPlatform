---
name: analytics-design
description: "Use after analytics-eda or when user wants to design a dashboard layout. Maps analytical questions to chart types using IBCS standards, plans layout using Gestalt principles, configures filters. Produces a dashboard design spec for user approval before building."
user-invocable: true
---

# Analytics Design — Dashboard Planning

This skill maps analytical questions to chart types, plans the dashboard layout, and produces a design specification for user approval. It follows IBCS SUCCESS rules for chart standards and Gestalt principles for layout. Reference `docs/ANALYTICS_FRAMEWORK.md` for the full methodology.

**This is a HITL (human-in-the-loop) gate. Do NOT proceed to building until the user explicitly approves the design.**

## Prerequisites

- Analytical questions from `projects/{project_slug}/intake.md`.
- EDA profile from `projects/{project_slug}/eda_profile.md`.
- If running standalone, you need at minimum a list of questions and knowledge of the available data.
- Write design spec to `projects/{project_slug}/design_spec.md` when complete.

## Procedure

### Step 1: Brainstorm Visualization Ideas (Diverge)

Before narrowing down, generate a broad set of 10-15 visualization ideas based on the data and questions. This is a creative divergence step.

For each idea, list:
- **Idea #**: Short title
- **Chart type**: What kind of visual
- **Data used**: Which columns/metrics
- **Question answered**: Which business question it addresses
- **Value**: Why this visual would be useful (High/Medium/Low)

Present all ideas to the user in a numbered table:

```
## Visualization Ideas (Brainstorm)

Based on the data profile and your questions, here are 10-15 possible visuals:

| # | Idea | Chart Type | Data | Answers | Value |
|---|------|-----------|------|---------|-------|
| 1 | Total Revenue KPI | Big Number | SUM(sales) | "How much total?" | High |
| 2 | Revenue by Month | Line | sales × order_date | "Trend over time?" | High |
| 3 | Sales by Category | Bar | sales × category | "Which category leads?" | High |
| 4 | Top 10 Products | Horizontal Bar | sales × product_name | "Best sellers?" | Medium |
| 5 | Regional Breakdown | Pie | sales × region | "Revenue share by region?" | Medium |
| 6 | Segment Comparison | Bar | sales × segment | "Consumer vs Corp vs Home?" | Medium |
| 7 | Monthly Heatmap | Heatmap | sales × month × year | "Seasonal patterns?" | Medium |
| 8 | Ship Mode Distribution | Pie | count × ship_mode | "How do we ship?" | Low |
| 9 | State-level Map | Map | sales × state | "Geographic hotspots?" | Medium |
| 10 | Sub-Category Ranking | Horizontal Bar | sales × sub_category | "Detailed breakdown?" | High |
| 11 | YoY Growth Trend | Line (dual) | sales by year | "Are we growing?" | High |
| 12 | Customer Count Trend | Line | distinct customers × month | "Customer base growth?" | Medium |
| 13 | Avg Order Value | Big Number | AVG(sales) | "Typical order size?" | Medium |
| 14 | Category × Region Matrix | Pivot Table | sales × category × region | "Multi-dim breakdown?" | Medium |
| 15 | Sales Detail Table | Table | all columns | "Raw data access?" | Low |
```

### Step 2: Narrow Down (Converge)

After presenting the brainstorm, ask the user:

```
Which visuals would you like to include? You can:
- Pick by number: "1, 2, 3, 5, 10"
- Say "top 8" to auto-select the highest-value ideas
- Add your own: "add a scatter plot of sales vs quantity"
- Remove: "skip 8 and 15"
```

If the user says "top N" or doesn't specify, auto-select based on:
1. All "High" value ideas first
2. Then "Medium" value ideas until reaching max_charts
3. Never include "Low" value ideas unless explicitly requested

**Rules for narrowing:**
- Max charts from preferences (default 8)
- Must include at least 1 KPI big number
- Must include at least 1 trend line (if temporal data exists)
- Avoid redundancy — don't include both a pie and a bar showing the same breakdown
- Prefer a variety of chart types over repetition

Once the user confirms their selection, proceed to Step 3.

### Step 3: Determine Dashboard Type

Based on the audience collected during intake, classify the dashboard:

| Audience | Dashboard Type | Characteristics |
|---|---|---|
| C-suite, executives, board | **Strategic** | High-level KPIs, trends, minimal detail, big numbers prominent |
| Directors, managers | **Tactical** | Comparison charts, period-over-period, drill-down capability |
| Team leads, supervisors | **Operational** | Real-time or near-real-time, status indicators, action-oriented |
| Analysts, data scientists | **Analytical** | Detail-heavy, pivot tables, multiple dimensions, exploration-friendly |

The dashboard type influences chart selection, layout density, and complexity.

### Step 4: Map Selected Ideas to Chart Specs

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

### Step 5: Plan Virtual Datasets

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

### Step 6: Plan Layout

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

### Step 7: Plan Filter Bar

Select columns for the native filter bar:

1. **Categorical columns** with 2-50 distinct values (from EDA classification) are filter candidates.
2. **Time range filter**: Always include if a temporal column exists.
3. **Cross-filter**: Enable cross-filtering so clicking a bar/slice filters the entire dashboard.

Prioritize filters that:
- Align with the user's stated filter preferences (from intake).
- Represent key business dimensions (e.g., region, product category, department).
- Have reasonable cardinality (not too many, not too few values).

### Step 8: Apply Chart Cap

Respect the `max_charts` preference from intake:
- If total planned charts exceeds `max_charts`, prioritize by: KPIs first, then the chart most directly answering each question, then supporting charts.
- Inform the user which charts were cut and why.
- Suggest that cut charts could be added to a secondary dashboard.

### Step 9: Present Design Spec for Approval

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
