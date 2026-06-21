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

Before narrowing down, generate 10-15+ visualization ideas using a **structured question framework**. Don't just list random charts — systematically explore the data through 6 question categories.

#### Question Framework (6 categories)

Walk through each category and generate ideas based on available columns from the EDA profile and insights:

**A. Overview / KPIs** — "How are we doing overall?"
- Total revenue/sales/profit KPI
- Total orders/transactions count
- Average order value / average margin
- Customer count
- Period-over-period comparison (YoY, MoM)

**B. Trends** — "How is it changing over time?"
- Revenue/profit trend line (monthly, weekly, quarterly)
- Order volume over time
- Seasonal pattern detection (which months peak?)
- YoY growth comparison (overlay years)
- Moving average to smooth noise

**C. Composition** — "What makes up the total?"
- Revenue by category/segment/region (bar or pie)
- Share of total (%) by dimension
- Stacked composition over time (area chart)
- Pareto: top N items = X% of total

**D. Comparison** — "How do things compare?"
- Category vs category (bar chart)
- Region vs region
- Segment profitability comparison
- Top 10 / Bottom 10 ranking
- Sales vs Profit scatter (correlation)

**E. Profitability & Efficiency** — "Where do we make/lose money?" (if profit/discount/cost data exists)
- Profit margin by category/sub-category
- Discount impact on profit
- Loss-making products/regions
- Revenue vs profit divergence (high sales ≠ high profit)
- Cost efficiency by shipping mode

**F. Detail / Drill-down** — "Show me the specifics"
- Detailed table with all dimensions + metrics
- Pivot table (category × region matrix)
- Top/bottom products by name
- Customer-level detail
- Geographic drill-down (state/city)

#### Generate Ideas Table

For each relevant idea from the 6 categories above, produce a row:

```
## Visualization Ideas (Brainstorm)

Based on the data profile, insights, and your questions:

| # | Category | Idea | Chart Type | Data | Value |
|---|----------|------|-----------|------|-------|
| 1 | A. KPI | Total Revenue | Big Number | SUM(sales) | High |
| 2 | A. KPI | Total Orders | Big Number | COUNT(DISTINCT order_id) | High |
| 3 | A. KPI | Avg Order Value | Big Number | AVG(sales) | Medium |
| 4 | B. Trend | Monthly Revenue Trend | Line | sales × month | High |
| 5 | B. Trend | Seasonal Heatmap | Heatmap | sales × month × year | Medium |
| 6 | C. Composition | Revenue by Category | Bar | sales × category | High |
| 7 | C. Composition | Revenue Share | Pie | sales × region | Medium |
| 8 | D. Comparison | Top 10 Sub-Categories | H-Bar | sales × sub_category | High |
| 9 | D. Comparison | Revenue by Region | Bar | sales × region | High |
| 10 | D. Comparison | Sales vs Profit | Scatter | sales vs profit | Medium |
| 11 | E. Profit | Margin by Category | Bar | margin% × category | High |
| 12 | E. Profit | Discount Impact | Bar | avg_profit × discount_band | Medium |
| 13 | E. Profit | Loss Makers | H-Bar | profit × sub_category (negative) | High |
| 14 | F. Detail | Category × Region Matrix | Pivot | sales × category × region | Medium |
| 15 | F. Detail | Detail Table | Table | all dimensions + metrics | Low |
```

**Important**: Only generate ideas for columns that actually exist in the data. If there's no `profit` column, skip category E. Reference the EDA profile and insights for available columns.

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
