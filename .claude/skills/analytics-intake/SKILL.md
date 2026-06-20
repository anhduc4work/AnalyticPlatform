---
name: analytics-intake
description: "Use when user wants to start an analytics project, build a dashboard, or analyze data. Collects required inputs: data source connection, business context (audience, questions, KPIs), and data description. Validates inputs before proceeding."
user-invocable: true
---

# Analytics Intake — Business Understanding

This skill implements the CRISP-DM Business Understanding phase. Your job is to collect, validate, and structure the inputs needed before any data work begins. Reference `docs/ANALYTICS_FRAMEWORK.md` for the full methodology.

## Required Inputs

You must collect three categories of information from the user. Do NOT guess or assume any of these — if missing, ask the user directly.

### 1. Data Source Connection

Collect ONE of the following:
- **Existing database**: The database ID or name already registered in Superset.
- **New connection**: A SQLAlchemy connection string (e.g., `postgresql://user:pass@host:5432/dbname`) or equivalent connection details (host, port, database name, credentials).

### 2. Business Context

Collect ALL of the following:
- **Audience**: Who will consume this dashboard? (e.g., executive team, operations manager, sales reps, analysts). This determines the dashboard type (strategic, tactical, operational, analytical).
- **Domain**: What business area does this cover? (e.g., sales, marketing, finance, HR, operations, product).
- **Decisions**: What decisions should this dashboard support? What actions will viewers take based on the data?
- **Questions**: At least ONE analytical question the dashboard must answer (e.g., "How are monthly revenues trending?", "Which products have the highest return rate?", "What is our customer acquisition cost by channel?").
- **KPIs** (optional): Specific metrics or KPIs to track (e.g., revenue, conversion rate, churn rate, NPS).

### 3. Data Description

Collect ALL of the following:
- **What the data represents**: A plain-language description of the dataset (e.g., "e-commerce order transactions", "employee attendance records", "IoT sensor readings").
- **Key entities**: At least ONE entity the data describes (e.g., customers, orders, products, employees, devices).
- **Time column** (optional): The primary date/datetime column for time-series analysis (e.g., `order_date`, `created_at`).
- **Relationship hints** (optional): Known relationships between tables (e.g., "orders.customer_id links to customers.id", "each product belongs to one category").

## Optional Inputs

### Dashboard Preferences

These are optional — use sensible defaults if not provided:
- **Title**: Dashboard title (default: derived from domain + audience).
- **max_charts**: Maximum number of charts on the dashboard (default: 8).
- **Complexity**: `simple` (3-5 charts), `standard` (6-8 charts), or `detailed` (9-12 charts). Overrides max_charts if provided.
- **Filters**: Specific filter dimensions the user wants (e.g., "filter by region, date range, product category").
- **Refresh**: Auto-refresh interval (e.g., "none", "hourly", "daily").

## Validation Rules

Before proceeding, confirm ALL of the following are present:

| Input | Required? | Validation |
|---|---|---|
| Connection (DB id/name OR connection string) | YES | Must be non-empty |
| Audience | YES | Must be non-empty |
| At least 1 analytical question | YES | Must be a concrete, answerable question |
| Data description | YES | Must be non-empty |
| At least 1 key entity | YES | Must be non-empty |

If any required input is missing, ask the user for it. List exactly what is missing. Do not proceed until all validations pass.

## Procedure

1. **Greet and explain**: Briefly tell the user you will collect the information needed to build their analytics dashboard. Mention the three categories.
2. **Collect inputs**: Ask for the required inputs. You may collect them all at once or in stages depending on what the user provides. If the user gives partial information, acknowledge what you have and ask for what is missing.
3. **Validate**: Run the validation checks above. If anything fails, tell the user specifically what is needed.
4. **Confirm**: Present a structured summary of all collected inputs back to the user for confirmation. Use a clear format:

```
## Analytics Project Summary

### Data Source
- Connection: [database name or connection details]

### Business Context
- Audience: [who]
- Domain: [what area]
- Decisions: [what actions]
- Questions:
  1. [question 1]
  2. [question 2]
  ...
- KPIs: [list or "none specified"]

### Data Description
- Description: [what the data represents]
- Key Entities: [list]
- Time Column: [column name or "to be discovered"]
- Relationships: [hints or "to be discovered"]

### Dashboard Preferences
- Title: [title]
- Max Charts: [number]
- Complexity: [level]
- Filters: [list or "to be determined from data"]
- Refresh: [interval or "none"]
```

5. **Create project folder**: Create a subfolder under `projects/` for this project:
   ```
   projects/
   └── {project_slug}/           # e.g. "superstore-sales", "plantex-cashflow"
       ├── intake.md             # The structured summary from step 4
       ├── data/                 # Raw data files (CSV, etc.) if any
       └── output/               # Will hold .docx and exports later
   ```
   - Derive `project_slug` from the project title (lowercase, hyphens, no spaces)
   - Write the structured summary to `projects/{project_slug}/intake.md`
   - This folder will be used by all downstream skills (EDA writes `eda_profile.md`, design writes `design_spec.md`, build writes output files)

6. **Hand off**: Suggest the user run `/analytics-eda` next to profile and explore the data.

## Important Notes

- Never fabricate business context. The user is the domain expert.
- If the user provides a vague question like "show me the data", push back and ask for specifics: Who is the audience? What decisions will this support? What questions should it answer?
- Multiple questions are encouraged — they directly map to charts later.
- If the user mentions tables or columns by name, record those as relationship hints and entity names.
