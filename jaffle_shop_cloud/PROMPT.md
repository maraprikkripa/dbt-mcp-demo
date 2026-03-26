# jaffle_shop_cloud (dbt Cloud + BigQuery) — Autonomous Setup Prompt

Use this prompt in a new Claude Code conversation inside `dbt-mcp-demo/` to build
the complete jaffle_shop_cloud project and wire it to dbt Cloud.

---

## Prerequisites
- GCP project `bespin-us-demo`, BigQuery API + Storage API enabled
- Service account with `BigQuery Data Editor` + `BigQuery Job User` + `BigQuery Read Session User`
- JSON key at `keys/bespin-us-demo-3ab1ffe14924.json`
- GitHub repo `maraprikkripa/dbt-mcp-demo` accessible
- dbt Cloud account at cloud.getdbt.com

---

## Prompt

I want to build the jaffle_shop_cloud dbt project targeting BigQuery via dbt Cloud.
GCP project: `bespin-us-demo`. Dataset: `jaffle_shop_cloud`.
GitHub: `maraprikkripa/dbt-mcp-demo`, subdirectory `jaffle_shop_cloud/`.
Complete all steps below.

### 1 — Scaffold and copy models

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo
dbt init --project-name jaffle_shop_cloud --skip-profile-setup
cp -r jaffle_shop/seeds/*  jaffle_shop_cloud/seeds/
cp -r jaffle_shop/macros/* jaffle_shop_cloud/macros/
cp -r jaffle_shop/models/* jaffle_shop_cloud/models/
cp jaffle_shop/packages.yml jaffle_shop_cloud/
```

### 2 — Update jaffle_shop_cloud/dbt_project.yml

Remove `+static_analysis: strict` — not supported in dbt-core.

```yaml
name: jaffle_shop_cloud
profile: jaffle_shop_cloud
seed-paths: ["seeds"]
model-paths: ["models"]
macro-paths: ["macros"]
seeds:
  jaffle_shop_cloud:
    +schema: raw
models:
  jaffle_shop_cloud:
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    marts:
      +materialized: table
```

### 3 — Add profile to ~/.dbt/profiles.yml

```yaml
jaffle_shop_cloud:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: bespin-us-demo
      dataset: jaffle_shop_cloud
      keyfile: "C:/Users/kriparam/Documents/dbt-mcp-demo/keys/bespin-us-demo-3ab1ffe14924.json"
      threads: 4
      timeout_seconds: 300
```

### 4 — Verify locally

```bash
cd jaffle_shop_cloud
dbt debug        # must show: All checks passed!
dbt deps
dbt build        # confirm all seeds, models, tests pass against jaffle_shop_cloud dataset
```

Log output:
```bash
dbt build 2>&1 | tee run_logs/build_$(date +%Y%m%d_%H%M%S).log
```

### 5 — Push to GitHub

Verify `.gitignore` has `keys/` before staging.

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo
git init
git remote add origin https://github.com/maraprikkripa/dbt-mcp-demo.git
git add jaffle_shop/ jaffle_shop_bq/ jaffle_shop_cloud/ CLAUDE.md SETUP.md COMMANDS.md phase4-prompt.md .gitignore .mcp.json
git commit -m "Add jaffle_shop, jaffle_shop_bq, jaffle_shop_cloud projects"
git branch -M main
git push -u origin main
```

### 6 — dbt Cloud setup (manual steps in UI)

Guide the user through:

1. **New project** → name: `jaffle_shop_cloud` → warehouse: BigQuery
2. **BigQuery connection** → upload `bespin-us-demo-3ab1ffe14924.json` → dataset: `jaffle_shop_cloud` → test connection
3. **GitHub connection** → repo: `maraprikkripa/dbt-mcp-demo` → subdirectory: `jaffle_shop_cloud`
4. **Development environment** → dbt version: latest → dataset: `jaffle_shop_cloud`
5. **Create job** → name: "Daily build" → commands: `dbt deps`, `dbt build` → run manually first
6. **Run job** → confirm all pass in dbt Cloud run logs

### 7 — Verify in BigQuery Console

```sql
SELECT 'raw_orders' AS layer, COUNT(*) AS rows FROM `bespin-us-demo.jaffle_shop_cloud_raw.raw_orders`
UNION ALL SELECT 'stg_orders', COUNT(*) FROM `bespin-us-demo.jaffle_shop_cloud.stg_orders`
UNION ALL SELECT 'fct_orders', COUNT(*) FROM `bespin-us-demo.jaffle_shop_cloud.fct_orders`
UNION ALL SELECT 'dim_customers', COUNT(*) FROM `bespin-us-demo.jaffle_shop_cloud.dim_customers`;
```

---

## Success criteria
- `dbt debug` passes in jaffle_shop_cloud/
- `dbt build` passes locally — 6 seeds, 14+ models, 41+ tests against `jaffle_shop_cloud` dataset
- Code pushed to `maraprikkripa/dbt-mcp-demo` with `jaffle_shop_cloud/` subdirectory visible
- dbt Cloud project created, connected to GitHub and BigQuery
- dbt Cloud job runs successfully — tables visible in `bespin-us-demo.jaffle_shop_cloud`
