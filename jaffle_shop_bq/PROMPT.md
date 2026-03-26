# jaffle_shop_bq (BigQuery) — Autonomous Setup Prompt

Use this prompt in a new Claude Code conversation inside `dbt-mcp-demo/` to build
the complete jaffle_shop_bq BigQuery project from scratch.

---

## Prerequisites (complete before running this prompt)
- GCP project `bespin-us-demo` with BigQuery API enabled
- Service account `dbt-jaffle-shop` with `BigQuery Data Editor` + `BigQuery Job User` roles
- JSON key saved at: `C:/Users/kriparam/Documents/dbt-mcp-demo/keys/bespin-us-demo-3ab1ffe14924.json`
- `keys/` in `.gitignore`

---

## Prompt

I want to build the jaffle_shop_bq dbt project targeting BigQuery using dbt-fusion.
GCP project: `bespin-us-demo`. Dataset: `jaffle_shop_fusion`. Complete all steps below.

### 1 — Scaffold the project

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo
dbt init --project-name jaffle_shop_bq --skip-profile-setup
```

### 2 — Copy models from the DuckDB project

```bash
cp -r jaffle_shop/seeds/* jaffle_shop_bq/seeds/
cp -r jaffle_shop/macros/* jaffle_shop_bq/macros/
cp -r jaffle_shop/models/* jaffle_shop_bq/models/
cp jaffle_shop/packages.yml jaffle_shop_bq/
```

### 3 — Update jaffle_shop_bq/dbt_project.yml

```yaml
name: jaffle_shop_bq
profile: jaffle_shop_bq
seed-paths: ["seeds"]
model-paths: ["models"]
macro-paths: ["macros"]
seeds:
  jaffle_shop_bq:
    +schema: raw
models:
  jaffle_shop_bq:
    +static_analysis: strict
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    marts:
      +materialized: table
```

### 4 — Add BigQuery profile to ~/.dbt/profiles.yml

```yaml
jaffle_shop_bq:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: bespin-us-demo
      dataset: jaffle_shop_fusion
      keyfile: "C:/Users/kriparam/Documents/dbt-mcp-demo/keys/bespin-us-demo-3ab1ffe14924.json"
      threads: 4
      timeout_seconds: 300
```

### 5 — Verify connection and build

```bash
cd jaffle_shop_bq
dbt debug           # must show: All checks passed!
dbt deps
dbt build
```

Expected: 6 seeds + 14+ models + 41 tests — all pass in BigQuery.

### 6 — Demo workflow — show data at each layer

Run layer by layer and show results:

```bash
dbt seed
dbt show --select source:ecom.raw_orders        # raw: cents, messy names

dbt run --select staging
dbt show --select stg_orders                    # staging: dollars, renamed

dbt run --select intermediate
dbt show --select int_orders_enriched           # intermediate: customer + location joined

dbt run --select marts
dbt show --select fct_orders                    # gold: item counts, gross margin
dbt show --select dim_customers                 # gold: lifetime spend, segments

dbt test --select intermediate marts            # expected: 41/41 pass
```

### 7 — Add dbt-bq MCP server entry

In `dbt-mcp-demo/.mcp.json`, add alongside the existing `dbt` entry:

```json
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
```

---

## Success criteria
- `dbt debug` passes in jaffle_shop_bq/
- `dbt build` passes — 6 seeds, 14+ models, 41 tests in BigQuery
- `dim_customers` has rows with `customer_segment` in Gold/Silver/Bronze
- `fct_orders` has non-null `total_gross_margin` and `customer_order_number`
- Tables visible in BigQuery Console under `bespin-us-demo.jaffle_shop_fusion`
