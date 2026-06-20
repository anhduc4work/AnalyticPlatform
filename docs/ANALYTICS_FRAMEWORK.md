# Analytics & Dashboard Framework

A systematized reference of methodologies, standards, and principles that govern the AnalyticPlatform pipeline. Every output (dashboard, chart, document) should be traceable to these foundations.

---

## 1. Analytics Methodology: CRISP-DM

We follow **CRISP-DM** (Cross-Industry Standard Process for Data Mining) — the most widely adopted analytics methodology (49% adoption rate).

### Why CRISP-DM over alternatives

| Methodology | Origin | Strength | Weakness | Our Use |
|-------------|--------|----------|----------|---------|
| **CRISP-DM** | Industry consortium, 1996 | Business-first, iterative, domain-agnostic | No team/DevOps guidance | Primary methodology |
| SEMMA | SAS Institute | Strong on modeling | Skips business understanding | Not used |
| TDSP | Microsoft | DevOps-integrated, scalable | Azure-centric | Borrow CI/CD ideas |
| KDD | Academic | Rigorous, foundational | Too academic, no deployment | Theoretical reference |
| OSEMN | Community | Simple, memorable | No business/deployment phase | Not used |

### CRISP-DM × Our Pipeline

| CRISP-DM Phase | Our Stage | Output |
|----------------|-----------|--------|
| 1. Business Understanding | INTAKE + BRAINSTORM | Ch 1-2 (Charter + Requirements) |
| 2. Data Understanding | CONNECT + DISCOVER + EDA | Ch 3 (Data Assessment) |
| 3. Data Preparation | ETL | Ch 4 (Data Dictionary) |
| 4. Modeling (BI context) | DESIGN | Ch 5 (Dashboard Design) |
| 5. Evaluation | PLAN REVIEW + VISUAL REVIEW | Ch 6 (UAT Test Plan) |
| 6. Deployment | BUILD + REPORT | Ch 7-8 (User Guide + Handoff) |

---

## 2. Analytics Classification

### By Purpose (Analytics Maturity Model)

| Level | Type | Question | Method | Complexity | Value |
|-------|------|----------|--------|------------|-------|
| 1 | **Descriptive** | What happened? | Aggregation, reporting | Low | Low |
| 2 | **Diagnostic** | Why did it happen? | Drill-down, comparison, YoY | Medium | Medium |
| 3 | **Predictive** | What will happen? | Forecasting, regression, ML | High | High |
| 4 | **Prescriptive** | What should we do? | Optimization, simulation | Highest | Highest |

**Pipeline applies:** Level 1-2 by default. Level 3-4 requires additional ML tooling.

### By Dashboard Type

| Type | Audience | Refresh | Data Depth | Design Focus |
|------|----------|---------|------------|--------------|
| **Strategic** | C-suite, executives | Monthly/quarterly | High-level KPIs | Simplicity, trends, targets |
| **Tactical** | Mid-management | Weekly/monthly | Department-level | Comparisons, breakdowns |
| **Operational** | Team leads, operators | Real-time/daily | Transactional | Speed, alerts, detail |
| **Analytical** | Analysts, data team | Ad hoc | Full granularity | Flexibility, drill-down |

**Pipeline determines dashboard type from inputs:**
- `audience = "executive"` → Strategic
- `audience = "manager"` → Tactical
- `audience = "operator"` → Operational
- `audience = "analyst"` → Analytical

---

## 3. Dashboard Design Standards: IBCS SUCCESS

We follow **IBCS** (International Business Communication Standards) — the only formal standard for business dashboard design.

### SUCCESS Rules

| Letter | Rule | Meaning | Application |
|--------|------|---------|-------------|
| **S** | SAY | Convey a message | Every chart must answer a specific question. Title = the insight, not the data. |
| **U** | UNIFY | Apply semantic notation | Consistent colors, shapes, patterns across all charts. Same meaning = same visual. |
| **C** | CONDENSE | Increase information density | Remove chartjunk. Maximize data-ink ratio. Small multiples over separate pages. |
| **C** | CHECK | Ensure visual integrity | No truncated axes. No 3D. No dual axes unless clearly labeled. Proportional areas. |
| **E** | EXPRESS | Choose proper visualization | Match chart type to data type (see decision matrix below). |
| **S** | SIMPLIFY | Avoid clutter | Remove gridlines, borders, legends when possible. Direct labeling. |
| **S** | STRUCTURE | Organize content | Information hierarchy: KPIs → Trends → Comparisons → Details (top to bottom). |

### Three Pillars

| Pillar | Scope | Rules |
|--------|-------|-------|
| **Conceptual** | How to organize content | STRUCTURE, SAY |
| **Perceptual** | Which visualizations to use | EXPRESS, CHECK, CONDENSE, SIMPLIFY |
| **Semantic** | Consistent notation | UNIFY |

### IBCS Semantic Notation (key patterns)

| Scenario | Notation |
|----------|----------|
| Actual values | Solid fill |
| Previous year | Outline / lighter shade |
| Plan/budget | Hatched fill |
| Forecast | Striped fill |
| Variance positive | Green / upward triangle |
| Variance negative | Red / downward triangle |
| Highlight | Dark accent color |

---

## 4. Visual Design Principles

### Gestalt Principles (perceptual grouping)

| Principle | Rule | Dashboard Application |
|-----------|------|----------------------|
| **Proximity** | Close items = same group | Group related charts in the same row |
| **Similarity** | Same look = same meaning | Same color for same company across all charts |
| **Continuity** | Eye follows smooth lines | Align chart edges, consistent grid |
| **Closure** | Brain completes partial shapes | Cards/borders not needed if spacing is clear |
| **Figure-Ground** | Distinguish foreground from background | White cards on gray background |

### Information Hierarchy (top → bottom)

```
┌─────────────────────────────────────────────┐
│  KPIs (Big Numbers)                         │  ← Answer first: "How are we doing?"
├─────────────────────────────────────────────┤
│  Trends (Time Series)                       │  ← Context: "How is it changing?"
├─────────────────────────────────────────────┤
│  Comparisons (Bar, Pie)                     │  ← Breakdown: "Where/what/who?"
├─────────────────────────────────────────────┤
│  Detail (Table, Matrix)                     │  ← Evidence: "Show me the numbers"
└─────────────────────────────────────────────┘
```

### Chart Type Decision Matrix

| Data Relationship | Best Chart | Superset `viz_type` |
|-------------------|-----------|---------------------|
| Single KPI value | Big Number | `big_number` |
| Trend over time | Line | `echarts_timeseries_line` |
| Category comparison | Bar (vertical) | `echarts_timeseries_bar` |
| Ranking | Bar (horizontal) | `echarts_timeseries_bar` (horizontal) |
| Part of whole | Pie / Donut | `pie` |
| Composition over time | Stacked Area/Bar | `echarts_timeseries_bar` (stacked) |
| Correlation | Scatter | `echarts_timeseries_scatter` |
| Distribution | Histogram / Box | `box_plot` |
| Multi-dimensional | Pivot Table | `pivot_table_v2` |
| Hierarchical detail | Handlebars (custom HTML) | `handlebars` |
| Geographic | Map | `deck_geojson` |

### Color Guidelines

| Use Case | Approach |
|----------|----------|
| Categories (companies) | Distinct hues, max 5-7 |
| Sequential (low→high) | Single hue, light→dark |
| Diverging (neg→pos) | Red→White→Green |
| Highlight vs context | Bold vs muted |
| Accessibility | Test with colorblind simulator |

---

## 5. Input → Output Mapping

This is how the pipeline ensures the output satisfies the input.

### Input determines Dashboard Type

```
audience + frequency → Dashboard Type → Design Rules
```

| Input: audience | Input: questions | → Dashboard Type | → Layout | → Chart Complexity |
|-----------------|-----------------|------------------|----------|--------------------|
| Executive | "How is the business?" | Strategic | KPIs + 1-2 trends | Simple (big_number, line) |
| Manager | "What's driving revenue?" | Tactical | KPIs + trends + comparisons | Moderate (+ bar, pie, table) |
| Operator | "What's happening now?" | Operational | Real-time KPIs + alerts | Simple + auto-refresh |
| Analyst | "Let me explore the data" | Analytical | Full drill-down, pivots, SQL | Advanced (+ pivot, handlebars) |

### Input determines Chart Selection

```
question → data pattern → chart type (per EXPRESS rule)
```

| Question Pattern | Data Pattern | Chart |
|-----------------|--------------|-------|
| "What is the total X?" | Single metric | Big Number |
| "How is X changing over time?" | Metric × time | Line |
| "Compare X across Y" | Metric × category | Bar |
| "What % of total is X?" | Part of whole | Pie |
| "Break down X by Y and Z" | Metric × 2 categories | Stacked bar or pivot |
| "Show all detail" | Multi-column raw data | Table or handlebars |

### Input determines Filter Configuration

```
data.key_entities + EDA.categorical_columns → filters
```

| Column Property | → Filter Type |
|-----------------|---------------|
| Temporal column | Time range picker |
| Categorical, 2-20 distinct values | Select dropdown |
| Categorical, 20-100 distinct values | Searchable select |
| Categorical, 100+ distinct values | Text search |
| Numeric range | Range slider |

---

## 6. Quality Checklist (Evaluation Gate)

Before presenting a dashboard, verify against these standards:

### IBCS Compliance

- [ ] Every chart has a clear title that states the insight (SAY)
- [ ] Colors are consistent across charts — same entity = same color (UNIFY)
- [ ] No wasted space — charts are condensed, no empty quadrants (CONDENSE)
- [ ] Axes start at zero, no misleading scales (CHECK)
- [ ] Chart type matches the data relationship (EXPRESS)
- [ ] No 3D charts, no chartjunk, no excessive gridlines (SIMPLIFY)
- [ ] Layout follows information hierarchy: KPI → Trend → Comparison → Detail (STRUCTURE)

### Gestalt Compliance

- [ ] Related charts are grouped in the same row (Proximity)
- [ ] Same entity has same color everywhere (Similarity)
- [ ] Grid is aligned, no ragged edges (Continuity)

### Functional

- [ ] Filters work and apply to all relevant charts
- [ ] Cross-filtering is enabled
- [ ] KPI numbers match source query validation
- [ ] Dashboard loads in < 10 seconds
- [ ] Date range filter covers the full data range

---

## References

- [CRISP-DM - Data Science PM](https://www.datascience-pm.com/crisp-dm-2/)
- [IBCS Standards](https://www.ibcs.com/ibcs-standards-1-2/)
- [IBCS SUCCESS Framework](https://www.ibcs.com/)
- [Gestalt Principles for Dashboard Design](https://playfairdata.com/applying-gestalt-principles-to-dashboard-design/)
- [Dashboard Types - Klipfolio](https://www.klipfolio.com/blog/starter-guide-to-dashboards)
- [Dashboard Design Principles](https://www.rib-software.com/en/blogs/bi-dashboard-design-principles-best-practices)
- Edward Tufte — *The Visual Display of Quantitative Information*
- Stephen Few — *Information Dashboard Design*
- Rolf Hichert — *IBCS Standards v1.2*
