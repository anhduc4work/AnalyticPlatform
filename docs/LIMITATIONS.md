# Known Limitations & Testing Plan

## Current Limitations (observed during development)

### Dashboard Building

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| **Ghost chart error** | Deleting/replacing charts leaves phantom references in dashboard | Must update position_json + json_metadata in single API call (documented in CLAUDE.md) |
| **No native drill-down hierarchy** | Superset doesn't have Power BI-style collapsible hierarchy tables | Use Handlebars chart with custom HTML for hierarchy display |
| **Layout via API is fragile** | position_json is a complex JSON structure, easy to break | Always validate chart IDs exist before referencing in layout |
| **Chart type limitations** | Only 7 chart types via official MCP: big_number, xy, pie, table, pivot_table, handlebars, mixed_timeseries | Community MCP supports more types but with less convenient API |
| **No conditional formatting** | Superset tables/pivots don't support cell-level color rules like Power BI | Use Handlebars chart with CSS for conditional styling |

### Data Loading

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| **CSV date format sensitivity** | PostgreSQL rejects dates if format doesn't match datestyle | Pre-process CSV or SET datestyle before COPY |
| **Encoding issues** | Non-UTF8 characters (e.g. \xa0) cause COPY to fail | Clean CSV with Python before loading |
| **No direct CSV upload via API** | Superset CSV upload API requires multipart form, tricky via MCP | Load into PostgreSQL directly, then register as dataset |
| **Column type inference** | Superset may misidentify varchar dates as strings | Create virtual datasets with explicit CAST |

### MCP Integration

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| **Official MCP requires `request` wrapper** | `{"request": {...}}` needed for all tools | Documented in CLAUDE.md |
| **`add_chart_to_existing_dashboard` appends** | Can't replace chart, only add new row | Use direct position_json update instead |
| **Filter scope limited to chartsInScope** | Filters only apply to explicitly listed chart IDs | Must update chartsInScope when adding/removing charts |
| **No undo/version history via API** | Dashboard changes can't be rolled back | Export before making changes |

### Document Export (.docx)

| Limitation | Impact | Workaround |
|-----------|--------|------------|
| **No auto-generated TOC** | python-docx can insert a TOC field but it only populates when opened in Word | Acceptable — user opens in Word and updates TOC |
| **No chart screenshots in .docx** | Document describes charts but doesn't embed images | Use Playwright to screenshot, then manually insert |
| **Table width** | Wide tables may overflow page margins | Limit column count or use landscape orientation |

### Scale & Performance

| Limitation | Impact | Estimated Threshold |
|-----------|--------|---------------------|
| **SQL Lab query timeout** | Large datasets may timeout during EDA | ~1M rows per table |
| **Dashboard load time** | Too many charts or heavy queries slow rendering | 8-10 charts max |
| **Virtual dataset performance** | Complex JOINs on large tables are slow | Pre-aggregate or create materialized views |

---

## Testing Plan: 10 Datasets

Test the full pipeline (intake → EDA → design → build → export) across 10 diverse Kaggle datasets to identify edge cases and measure reliability.

### Dataset Selection Criteria

- Mix of sizes: small (< 10K rows), medium (10K-100K), large (100K+)
- Mix of domains: retail, finance, marketing, operations, healthcare
- Mix of complexity: single table vs multi-table, clean vs messy
- Mix of date formats and column types

### Test Matrix

| # | Dataset | Source | Size | Domain | Complexity | Key Test |
|---|---------|--------|------|--------|------------|----------|
| 1 | Superstore Sales | Kaggle | 9.8K rows | Retail | Single table, clean | Baseline — should work perfectly |
| 2 | Chocolate Sales | Kaggle | ~1K rows | Retail | Very small, simple | Minimum viable data |
| 3 | Walmart Sales Forecast | Kaggle | ~6K rows | Retail | Multiple stores/depts | Multi-dimensional groupby |
| 4 | E-Commerce Customer Behavior | Kaggle | ~60K rows | E-commerce | Medium, text columns | Column type handling |
| 5 | Amazon Sales 2025 | Kaggle | ~500 rows | E-commerce | Tiny, recent | Minimal data edge case |
| 6 | Retail Store Inventory | Kaggle | ~30K rows | Operations | Forecasting columns | Non-standard columns |
| 7 | Marketing Sales Dataset | Kaggle | ~60K rows | Marketing | 60K rows, many features | Wide table handling |
| 8 | Online Retail Transaction | Kaggle | ~500K rows | Retail | Large, international | Scale test |
| 9 | Shopping Cart Database | Kaggle | ~10K rows | E-commerce | Relational (multi-table) | JOIN handling |
| 10 | Plantex Cashflow | Production | ~20K rows | POS/Finance | Real data, Aiven PG | Real-world validation |

### Metrics to Track Per Test

| Metric | How to Measure |
|--------|----------------|
| **Pipeline success** | Did all 4 stages complete? (intake, EDA, design, build) |
| **Charts created** | Count of charts successfully built vs planned |
| **Ghost chart errors** | Did any phantom chart references appear? |
| **Data loading issues** | Encoding, date format, type casting failures |
| **EDA accuracy** | Were column types correctly classified? |
| **Chart type selection** | Were appropriate chart types chosen for the data? |
| **Filter functionality** | Do native filters work correctly? |
| **Document export** | Did .docx generate with all selected chapters? |
| **Total time** | End-to-end pipeline duration |
| **Manual interventions** | How many times did a human need to fix something? |

### Test Execution

Each test follows this script:
1. Download dataset from Kaggle (via MCP)
2. Load into Superset PostgreSQL
3. Run `/analytics-intake` with standardized inputs
4. Run `/analytics-eda`
5. Run `/analytics-design` → approve
6. Run `/analytics-build` → verify with Playwright
7. Export .docx with sections [1-8]
8. Record all metrics
9. Document any failures or limitations found

### Success Criteria

| Rating | Definition |
|--------|-----------|
| Pass | Pipeline completes end-to-end, dashboard renders, .docx exports |
| Partial | Pipeline completes but with manual fixes needed (e.g. ghost chart fix, layout adjustment) |
| Fail | Pipeline breaks and cannot recover without code changes |

**Target: 8/10 Pass, 2/10 Partial, 0/10 Fail**

---

## Versioning

| Version | Date | Changes |
|---------|------|---------|
| 0.1 | 2026-06-20 | Initial limitations documented from Plantex project |
| 0.2 | TBD | Updated after 10-dataset test run |
