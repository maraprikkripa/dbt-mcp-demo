# jaffle_shop_bq — BigQuery Setup Guide

**Runtime:** dbt-fusion · **Warehouse:** BigQuery · **GCP project:** `bespin-us-demo`

---

## Prerequisites

```bash
dbt --version       # dbt-fusion 2.x (BigQuery support built in)
```

### GCP requirements
- GCP project: `bespin-us-demo`
- BigQuery datasets created:
  - `jaffle_shop_fusion` — models land here
  - `jaffle_shop_fusion_raw` — seeds land here (auto-created by dbt via +schema: raw)
- Service account `dbt-jaffle-shop` with roles:
  - `BigQuery Data Editor` (project level)
  - `BigQuery Job User` (project level)
- JSON key downloaded to: `C:/Users/kriparam/Documents/dbt-mcp-demo/keys/bespin-us-demo-3ab1ffe14924.json`

---

## Step 1 — Initialize the project

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo
dbt init --project-name jaffle_shop_bq --skip-profile-setup
cd jaffle_shop_bq
```

## Step 2 — Copy models from jaffle_shop

```bash
cp -r ../jaffle_shop/seeds/* seeds/
cp -r ../jaffle_shop/macros/* macros/
cp -r ../jaffle_shop/models/* models/
cp ../jaffle_shop/packages.yml .
```

## Step 3 — Update dbt_project.yml

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

## Step 4 — Add BigQuery profile to ~/.dbt/profiles.yml

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

## Step 5 — Verify connection

```bash
dbt debug
```

Expected output: `All checks passed!`

## Step 6 — Install packages and build

```bash
dbt deps
dbt build
```

Expected: 6 seeds + 12+ models + 41 tests — all pass in BigQuery.

## Step 7 — Verify data in BigQuery

```bash
dbt show --select fct_orders
dbt show --select dim_customers
```

Or query directly in BigQuery Console:
```sql
SELECT customer_segment, COUNT(*) as customers
FROM `bespin-us-demo.jaffle_shop_fusion.dim_customers`
GROUP BY customer_segment;
```

## Step 8 — Add to MCP server config

In `dbt-mcp-demo/.mcp.json`, add a second server entry:

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

## Key differences from DuckDB project

| Aspect | DuckDB | BigQuery |
|---|---|---|
| Auth | None | Service account JSON key |
| Schema naming | `main` / `main_raw` | `jaffle_shop_fusion` / `jaffle_shop_fusion_raw` |
| File locking | Yes | No |
| Query tool | DuckDB CLI | BigQuery Console or `dbt show` |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `403 Access Denied` | Check service account has both BigQuery roles at project level |
| `dataset not found` | Create `jaffle_shop_fusion` dataset in BigQuery console first |
| `keyfile not found` | Verify path uses forward slashes, key file exists |
| `dbt debug` fails | Run `dbt debug` to see exact error, check profiles.yml path |
