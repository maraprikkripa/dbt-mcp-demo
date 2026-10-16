# jaffle_shop_bq — Autonomous Build Prompt

Use this prompt in a new Claude Code conversation opened inside `dbt-mcp-demo/`
to build and verify the jaffle_shop_bq BigQuery project end-to-end without any
manual steps.

---

## Context

The project is already fully scaffolded:
- All models, seeds, macros, and YAML files exist in `jaffle_shop_bq/`
- `~/.dbt/profiles.yml` has the `jaffle_shop_bq` profile pointing at `bespin-us-demo`
- Service account key is at `keys/bespin-us-demo-3ab1ffe14924.json`
- BigQuery datasets are created automatically by dbt-fusion on first run

Do NOT re-scaffold or re-init the project. Start from Step 1 below.

---

## Prompt

I want to build and verify the jaffle_shop_bq dbt project. It uses dbt-fusion
targeting BigQuery (project: bespin-us-demo, dataset: jaffle_shop_fusion).
The project is already scaffolded. Complete all steps below autonomously.

---

### Step 1 — Verify connection

Run `dbt debug` from inside `jaffle_shop_bq/`. It must show:
```
All checks passed
```
If it fails, check that the keyfile path in `~/.dbt/profiles.yml` is correct and
the file exists at `keys/bespin-us-demo-3ab1ffe14924.json`.

---

### Step 2 — Install packages

```bash
cd jaffle_shop_bq
dbt deps
```

---

### Step 3 — Build everything

```bash
dbt build
```

Expected output:
- 6 seeds loaded into `jaffle_shop_fusion_raw` dataset in BigQuery
- 8 view models created (staging + intermediate)
- 6 table models created (marts)
- 41+ tests — all pass
- No errors

If any model fails, read the error, fix it, and re-run `dbt build --select <failed_model>+`.

---

### Step 4 — Demo workflow — show data at each layer

Run each command and show the results so the user can see data flowing through
the four layers:

**Layer 1 — Raw (seeds)**
```bash
dbt show --select raw_orders --limit 5
```
What to point out: cents amounts (subtotal, tax_paid, order_total), raw column names

**Layer 2 — Staging**
```bash
dbt show --select stg_orders --limit 5
dbt show --select stg_customers --limit 5
```
What to point out: dollars instead of cents, renamed columns (id→order_id, customer→customer_id)

**Layer 3 — Intermediate**
```bash
dbt show --select int_orders_enriched --limit 5
dbt show --select int_order_items_enriched --limit 5
```
What to point out: customer_name and location_name joined in, gross_margin computed

**Layer 4 — Gold (marts)**
```bash
dbt show --select dim_customers --limit 10
dbt show --select fct_orders --limit 10
```
What to point out: customer_segment (Gold/Silver/Bronze), total_spend, total_gross_margin,
customer_order_number

---

### Step 5 — Business queries

Run these to show analytics-ready output:

```bash
# Customer segments breakdown
dbt show --select dim_customers --limit 100
# (summarise counts per customer_segment in your response)

# Top 10 customers by total spend
dbt show --select dim_customers --limit 10
# (sort by total_spend desc in your response)

# Revenue by location
dbt show --select fct_orders --limit 100
# (summarise total order_total per location_name in your response)
```

---

### Step 6 — Run lineage-aware tests

```bash
dbt test --select intermediate marts
```

Expected: 41 tests pass, 0 failures.

---

### Step 7 — Add dbt-bq MCP server to .mcp.json

Read `dbt-mcp-demo/.mcp.json`. Add a second server entry called `dbt-bq` alongside
the existing `dbt` entry:

```json
{
  "mcpServers": {
    "dbt": {
      "type": "stdio",
      "command": "uvx",
      "args": ["dbt-mcp"],
      "env": {
        "DBT_PROJECT_DIR": "C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop",
        "DBT_PATH": "C:/Users/kriparam/.local/bin/dbt.exe",
        "DISABLE_SEMANTIC_LAYER": "true",
        "DISABLE_DISCOVERY_API": "true"
      }
    },
    "dbt-bq": {
      "type": "stdio",
      "command": "uvx",
      "args": ["dbt-mcp"],
      "env": {
        "DBT_PROJECT_DIR": "C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop_bq",
        "DBT_PATH": "C:/Users/kriparam/.local/bin/dbt.exe",
        "DISABLE_SEMANTIC_LAYER": "true",
        "DISABLE_DISCOVERY_API": "true"
      }
    }
  }
}
```

---

## Success criteria

- [ ] `dbt debug` passes — "All checks passed"
- [ ] `dbt build` passes — 6 seeds, 14 models, 41+ tests, 0 errors
- [ ] `dim_customers` has rows with `customer_segment` in Gold / Silver / Bronze
- [ ] `fct_orders` has non-null `total_gross_margin` and `customer_order_number`
- [ ] Tables visible in BigQuery Console under `bespin-us-demo.jaffle_shop_fusion`
- [ ] `.mcp.json` has both `dbt` (DuckDB) and `dbt-bq` (BigQuery) entries

---

## Key facts for debugging

| Thing | Value |
|---|---|
| GCP project | `bespin-us-demo` |
| BQ dataset (models) | `jaffle_shop_fusion` |
| BQ dataset (seeds) | `jaffle_shop_fusion_raw` |
| Key file | `keys/bespin-us-demo-3ab1ffe14924.json` |
| Profile name | `jaffle_shop_bq` |
| dbt binary | `C:/Users/kriparam/.local/bin/dbt.exe` |
| Project dir | `C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop_bq` |
| Amounts in raw seeds | cents — converted to dollars in staging via `cents_to_dollars()` macro |
| dbt-fusion behaviour | Auto-detects seed column types — no `+column_types` needed (unlike dbt-core) |
