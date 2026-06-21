---
name: analytics-eda
description: "Use after analytics-intake or when user wants to profile/explore data in Superset. Connects to database, discovers schema, profiles tables (row counts, column types, nulls, distinct values, distributions), classifies columns, detects relationships, flags data quality issues."
user-invocable: true
---

# Analytics EDA — Data Understanding

This skill implements the CRISP-DM Data Understanding phase. Your job is to connect to the database, discover the schema, profile every table, classify columns, detect relationships, flag data quality issues, and register datasets in Superset. Reference `docs/ANALYTICS_FRAMEWORK.md` for the full methodology.

## Prerequisites

- Analytics intake should be completed — check `projects/{project_slug}/intake.md` for inputs.
- If running standalone, you need at minimum a database connection (ID, name, or connection string).
- Write EDA results to `projects/{project_slug}/eda_profile.md` when complete.

## Procedure

### Step 1: Connect to or Find the Database

No authentication step needed — bintocher auto-authenticates via env vars.

- If the user provided an existing database name/ID, call `superset_database_list` (bintocher) to find it.
- If the user provided a new connection string, call `superset_database_create` (bintocher) to register it.
- Capture the `database_id` for all subsequent queries.

### Step 2: Discover Schema

1. Call `superset_database_schemas` (bintocher) with the `database_id` to list available schemas.
2. Call `superset_database_tables` (bintocher) to list all tables and views.
3. Present the discovered schema to the user.

### Step 3: Profile Each Table

For each table, execute the following queries via `superset_sqllab_execute` (bintocher):

#### 4a. Row Count
```sql
SELECT COUNT(*) AS row_count FROM schema.table_name;
```

#### 4b. Column Metadata
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'schema' AND table_name = 'table_name'
ORDER BY ordinal_position;
```

#### 4c. Per-Column Profiling

For each column, gather statistics based on data type:

**All columns:**
```sql
SELECT
  COUNT(*) AS total_rows,
  COUNT(column_name) AS non_null_count,
  COUNT(*) - COUNT(column_name) AS null_count,
  ROUND(100.0 * (COUNT(*) - COUNT(column_name)) / NULLIF(COUNT(*), 0), 1) AS null_pct,
  COUNT(DISTINCT column_name) AS distinct_count
FROM schema.table_name;
```

**Numeric columns** (integer, float, decimal, numeric, real, double, bigint, smallint):
```sql
SELECT
  MIN(column_name) AS min_val,
  MAX(column_name) AS max_val,
  AVG(column_name) AS avg_val,
  STDDEV(column_name) AS stddev_val
FROM schema.table_name;
```

**Categorical columns** (varchar, text, char, enum — with distinct count <= 50):
```sql
SELECT column_name, COUNT(*) AS freq
FROM schema.table_name
WHERE column_name IS NOT NULL
GROUP BY column_name
ORDER BY freq DESC
LIMIT 20;
```

**Temporal columns** (date, timestamp, datetime, time):
```sql
SELECT
  MIN(column_name) AS earliest,
  MAX(column_name) AS latest
FROM schema.table_name;
```

Batch these queries where possible to reduce round-trips. Combine multiple column profiles into a single query per table when the database supports it.

### Step 4: Classify Columns

Assign each column one of the following types based on its data type and profile:

| Classification | Criteria |
|---|---|
| **Temporal** | Date/timestamp type, or name contains `date`, `time`, `created`, `updated`, `_at`, `_on` |
| **Categorical** | Text/varchar with distinct count between 2 and 50 |
| **High-cardinality text** | Text/varchar with distinct count > 50 or distinct count close to row count |
| **Numeric (measure)** | Numeric type that is NOT an ID or foreign key |
| **Identifier (dimension)** | Column name ends with `_id`, `_key`, `_code`, or is a primary key |
| **Boolean** | Boolean type or has exactly 2 distinct values |

### Step 5: Detect Relationships (Join Keys)

Look for potential join keys across tables:

1. **Name matching**: Find columns with identical names across different tables (e.g., `customer_id` in both `orders` and `customers`).
2. **ID suffix convention**: Columns ending in `_id` where the prefix matches another table name (e.g., `product_id` in `orders` likely joins to `products`).
3. **Cardinality check**: For candidate join keys, verify that the foreign key column's distinct values are a subset of (or equal to) the primary table's values.

Record detected relationships as: `table_a.column -> table_b.column (confidence: high/medium/low)`.

### Step 6: Flag Data Quality Issues

Flag any of the following issues:

| Issue | Threshold | Severity |
|---|---|---|
| High null percentage | > 20% nulls | Warning |
| Very low row count | < 10 rows | Warning |
| High-cardinality text (potential free text) | Distinct count > 50% of row count for text columns | Info |
| Single-value column | Only 1 distinct value | Warning |
| Possible duplicate rows | Row count much higher than distinct count of all columns combined | Info |
| Date range anomalies | Max date in the future or min date unreasonably old | Warning |

### Step 7: Register Physical Datasets

For each table that will be used in the dashboard, call `superset_dataset_create` (bintocher) to register it as a physical dataset in Superset. Use the following parameters:
- `database_id`: The database ID from Step 2.
- `table_name`: The table name.
- `schema`: The schema name.

Record the returned `dataset_id` for each registered dataset.

### Step 8: Present EDA Summary

Present a structured summary to the user:

```
## EDA Summary

### Database
- Name: [database name]
- ID: [database_id]
- Schema(s): [list]

### Tables Profiled
| Table | Rows | Columns | Null Issues | Quality Flags |
|---|---|---|---|---|
| table_1 | 10,000 | 12 | 2 cols > 20% | None |
| table_2 | 500 | 8 | 0 | Low row count |

### Column Classifications
| Table | Column | Type | Classification | Notes |
|---|---|---|---|---|
| orders | order_date | timestamp | Temporal | Primary time column |
| orders | status | varchar | Categorical | 5 distinct values |
| orders | total | decimal | Numeric (measure) | Range: 1.00 - 9999.99 |
| orders | customer_id | integer | Identifier | FK to customers |

### Detected Relationships
- orders.customer_id -> customers.id (high confidence)
- orders.product_id -> products.id (high confidence)

### Data Quality Issues
- [list any flagged issues with severity]

### Registered Datasets
- [list dataset names and IDs]

### Recommended Next Step
Run `/analytics-design` to map your analytical questions to chart types and plan the dashboard layout.
```

## Important Notes

- If a table has many columns (>30), prioritize profiling columns that are relevant to the user's analytical questions from intake.
- For very large tables (>1M rows), use `TABLESAMPLE` or `LIMIT` in profiling queries to avoid timeouts.
- If SQL execution fails for a specific query, log the error, skip that metric, and continue profiling. Do not halt the entire process for one failed query.
- Always present findings to the user before proceeding — this is informational, not a gate, but the user should be aware of any data quality issues before design begins.
