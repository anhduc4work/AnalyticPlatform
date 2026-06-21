---
name: analytics-insights
description: "Use after analytics-eda to generate data-driven insights, key findings, and recommendations. Runs analytical queries against the data, interprets results, identifies trends/anomalies/opportunities, and produces a written insights report. Feeds into dashboard design (chart titles) and project documentation (executive summary, recommendations)."
user-invocable: true
---

# Analytics Insights — Data Interpretation

This skill sits between EDA and Design. Your job is to query the data, interpret results, and produce actionable insights. These insights drive chart titles (IBCS SAY rule), the executive summary, and recommendations.

## Prerequisites

- EDA profile from `projects/{project_slug}/eda_profile.md` (column classifications, table stats).
- Business context from `projects/{project_slug}/intake.md` (audience, questions, KPIs).
- Write insights to `projects/{project_slug}/insights.md` when complete.

## Procedure

### Step 1: Run Analytical Queries

For each question from intake, run targeted SQL via `superset_sqllab_execute` (bintocher). Common patterns:

**KPI Totals:**
```sql
SELECT COUNT(*) as total_orders, ROUND(SUM(sales)::numeric, 2) as total_revenue,
       ROUND(AVG(sales)::numeric, 2) as avg_order_value
FROM table_name
```

**Time-series trends (YoY, MoM):**
```sql
SELECT EXTRACT(YEAR FROM date_col) as year,
       ROUND(SUM(sales)::numeric, 0) as revenue,
       COUNT(DISTINCT order_id) as orders
FROM table_name GROUP BY year ORDER BY year
```

**Category breakdown:**
```sql
SELECT category, ROUND(SUM(sales)::numeric, 0) as revenue,
       ROUND((SUM(sales) * 100.0 / (SELECT SUM(sales) FROM table_name))::numeric, 1) as pct
FROM table_name GROUP BY category ORDER BY revenue DESC
```

**Top/Bottom N:**
```sql
SELECT dimension, SUM(metric) as total
FROM table_name GROUP BY dimension ORDER BY total DESC LIMIT 10
```

**Period comparison (growth rate):**
```sql
WITH current AS (...), prior AS (...)
SELECT current.value, prior.value,
       ROUND(((current.value - prior.value) / prior.value * 100)::numeric, 1) as growth_pct
```

**Seasonality detection (monthly pattern):**
```sql
SELECT EXTRACT(MONTH FROM date_col) as month,
       ROUND(AVG(metric)::numeric, 0) as avg_value
FROM table_name GROUP BY month ORDER BY month
```

**Profitability analysis (if profit/margin columns exist):**
```sql
SELECT category, ROUND(SUM(sales)::numeric, 0) as revenue,
       ROUND(SUM(profit)::numeric, 0) as profit,
       ROUND((SUM(profit) * 100.0 / NULLIF(SUM(sales), 0))::numeric, 1) as margin_pct
FROM table_name GROUP BY category ORDER BY margin_pct DESC
```

**Discount impact analysis (if discount column exists):**
```sql
SELECT CASE WHEN discount = 0 THEN 'No Discount'
            WHEN discount <= 0.2 THEN '1-20%'
            ELSE '>20%' END as discount_band,
       COUNT(*) as orders, ROUND(AVG(profit)::numeric, 2) as avg_profit
FROM table_name GROUP BY 1 ORDER BY 1
```

**Pareto analysis (top N contributing to X% of total):**
```sql
WITH ranked AS (
  SELECT dimension, SUM(metric) as total,
         SUM(SUM(metric)) OVER (ORDER BY SUM(metric) DESC) as running_total,
         SUM(SUM(metric)) OVER () as grand_total
  FROM table_name GROUP BY dimension
)
SELECT dimension, total,
       ROUND((running_total * 100.0 / grand_total)::numeric, 1) as cumulative_pct
FROM ranked WHERE running_total <= grand_total * 0.8
```

**Correlation proxy (high sales vs low profit):**
```sql
SELECT dimension, ROUND(SUM(sales)::numeric, 0) as revenue,
       ROUND(SUM(profit)::numeric, 0) as profit,
       CASE WHEN SUM(sales) > 0 AND SUM(profit) / SUM(sales) < 0.05 THEN 'HIGH SALES LOW PROFIT'
            WHEN SUM(profit) < 0 THEN 'LOSS MAKER' ELSE 'OK' END as flag
FROM table_name GROUP BY dimension ORDER BY revenue DESC
```

### Step 2: Interpret Results

For each query result, produce an insight following this structure:

```
**Finding**: [What the data shows — factual statement]
**So what**: [Why it matters — business implication]
**Now what**: [Recommended action — what to do about it]
```

Categories of insights to look for:

| Pattern | Example | Insight Type |
|---------|---------|-------------|
| Dominant category | "Technology = 36.6% of revenue" | Concentration risk or strength |
| Growth/decline | "Revenue grew 20% YoY" | Trend direction |
| Anomaly | "2016 revenue dipped -4.3% then recovered" | Investigation needed |
| Gap | "South region = 17.2% vs West = 31.4%" | Opportunity or problem |
| Correlation | "High avg sale ($456) but low volume" | Pricing vs volume trade-off |
| Threshold | ">20% null rate in column X" | Data quality concern |
| Seasonality | "Nov-Dec = 35% of annual revenue" | Inventory/staffing planning |
| High sales low profit | "Furniture: $728K revenue but only 2% margin" | Pricing review needed |
| Discount erosion | "Orders with >20% discount avg -$5 profit" | Discount policy change |
| Pareto (80/20) | "Top 5 products = 40% of profit" | Focus on winners |
| Loss makers | "Tables sub-category: net loss of -$17K" | Discontinue or reprice |
| Segment difference | "Consumer = volume, Corporate = margin" | Segment-specific strategy |

### Step 3: Rank Insights by Impact

Prioritize insights by business impact:

1. **Critical** — Directly answers a stakeholder question or reveals a risk
2. **Important** — Supports decision-making, quantifies a KPI
3. **Informational** — Interesting pattern, useful context

### Step 4: Generate Chart Title Suggestions

For each planned chart, suggest an insight-driven title (IBCS SAY rule):

| Instead of | Use |
|-----------|-----|
| "Revenue by Category" | "Technology Leads Revenue at 37%" |
| "Monthly Revenue Trend" | "Revenue Growing 20% YoY Since 2017" |
| "Revenue by Region" | "West & East Drive 61% of Revenue" |
| "Top Sub-Categories" | "Phones & Chairs = 29% of All Sales" |

The title should state the finding, not describe the chart. The user can choose descriptive or insight-driven titles during design review.

### Step 5: Draft Executive Summary

Write a 3-5 sentence executive summary covering:
1. Overall performance (total KPIs)
2. Key trend (growth, decline, stability)
3. Biggest opportunity or risk
4. Top recommendation

Example:
> "Total revenue reached $2.26M across 4,922 orders (2015-2018), growing 20% YoY in the most recent year. Technology products drive the highest per-unit revenue ($456 avg) despite lower volume, while Office Supplies lead in transaction count. The South region represents the largest growth opportunity at only 17.2% of total revenue. Consider reallocating marketing spend from the saturated West region to accelerate South region growth."

### Step 6: Present Insights Report

Present to the user in this format:

```
## Data Insights Report

### Executive Summary
[3-5 sentences]

### Key Findings

#### 1. [Finding title] (Critical/Important/Informational)
- **Finding**: [factual statement with numbers]
- **So what**: [business implication]
- **Now what**: [recommended action]

#### 2. [Finding title]
...

### KPI Summary
| KPI | Value | Trend |
|-----|-------|-------|
| Total Revenue | $2.26M | ▲ 20% YoY |
| Total Orders | 4,922 | ▲ 28% YoY |
| Avg Order Value | $231 | ▼ -6% YoY |

### Chart Title Suggestions
| Chart | Descriptive Title | Insight-Driven Title |
|-------|------------------|---------------------|
| KPI 1 | "Total Revenue" | "Revenue Hits $2.26M" |
| Trend | "Monthly Revenue" | "Revenue Growing 20% YoY" |
| ...   | ...              | ...                  |

### Recommendations
1. [Top recommendation with rationale]
2. [Second recommendation]
3. [Third recommendation]

### Next Step
Run `/analytics-design` to map these insights to charts and plan the dashboard layout.
```

## Important Notes

- Always show actual numbers, not vague statements ("revenue is high"). Quantify everything.
- Compare against benchmarks when available (YoY, vs target, vs average).
- Don't fabricate insights — every finding must be backed by a query result.
- If the data doesn't support answering a stakeholder question, say so explicitly.
- Insights feed directly into the .docx document chapters 1 (Charter/Executive Summary) and 8 (Recommendations).
- The chart title suggestions are optional — the user decides during design review whether to use descriptive or insight-driven titles.
