# jaffle_shop_cloud — dbt Cloud + BigQuery Setup Guide

**Platform:** dbt Cloud · **Warehouse:** BigQuery · **GCP project:** `bespin-us-demo`
**GitHub repo:** `maraprikkripa/dbt-mcp-demo`

---

## Prerequisites
- GCP project `bespin-us-demo` with BigQuery API + BigQuery Storage API enabled
- Service account with `BigQuery Data Editor` + `BigQuery Job User` + `BigQuery Read Session User`
- JSON key at `C:/Users/kriparam/Documents/dbt-mcp-demo/keys/bespin-us-demo-3ab1ffe14924.json`
- GitHub account with access to `maraprikkripa/dbt-mcp-demo`
- dbt Cloud account at cloud.getdbt.com

---

## Part A — Local project setup

### Step 1 — Scaffold the project

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo
dbt init --project-name jaffle_shop_cloud --skip-profile-setup
```

### Step 2 — Copy models from jaffle_shop

```bash
cp -r jaffle_shop/seeds/*   jaffle_shop_cloud/seeds/
cp -r jaffle_shop/macros/*  jaffle_shop_cloud/macros/
cp -r jaffle_shop/models/*  jaffle_shop_cloud/models/
cp    jaffle_shop/packages.yml jaffle_shop_cloud/
```

### Step 3 — dbt_project.yml

Note: remove `+static_analysis: strict` — not supported in dbt-core (only dbt-fusion).

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

### Step 4 — Add profile to ~/.dbt/profiles.yml (local dev only)

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

### Step 5 — Verify locally

```bash
cd jaffle_shop_cloud && dbt debug && dbt deps && dbt build
```

---

## Part B — Push to GitHub

### Step 6 — Initialize git and push

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo

git init
git remote add origin https://github.com/maraprikkripa/dbt-mcp-demo.git

# Make sure keys/ is in .gitignore before staging
cat .gitignore    # should show keys/ and *.json

git add .
git commit -m "Initial commit: jaffle_shop, jaffle_shop_bq, jaffle_shop_cloud"
git branch -M main
git push -u origin main
```

---

## Part C — dbt Cloud setup

### Step 7 — Create a new project in dbt Cloud

```
cloud.getdbt.com → New Project
→ Name: jaffle_shop_cloud
→ Warehouse: BigQuery
```

### Step 8 — Connect BigQuery

```
Upload service account JSON key: bespin-us-demo-3ab1ffe14924.json
Project: bespin-us-demo
Dataset: jaffle_shop_cloud
```
Test connection → should show: Connection test passed.

### Step 9 — Connect GitHub repo

```
Repository: maraprikkripa/dbt-mcp-demo
Project subdirectory: jaffle_shop_cloud
```
dbt Cloud will only look at files inside `jaffle_shop_cloud/`.

### Step 10 — Configure development environment

```
dbt version: latest (or pin to 1.8.x)
Target name: dev
Dataset: jaffle_shop_cloud
Threads: 4
```

### Step 11 — Create a job

```
Jobs → New Job → name: "Daily build"
Commands:
  dbt deps
  dbt build

Schedule: manual (or set cron)
Target: production
Dataset: jaffle_shop_cloud_prod   ← separate from dev
```

### Step 12 — Run the job

```
Jobs → Daily build → Run Now
```

Watch the run logs in dbt Cloud UI. Expected: all seeds, models, tests pass.

---

## Part D — dbt Cloud vs local: key differences

| Thing | Local (profiles.yml) | dbt Cloud |
|---|---|---|
| BigQuery auth | keyfile path | JSON key uploaded in UI |
| Dataset | `jaffle_shop_cloud` | configured per environment |
| Running dbt | `dbt build` in terminal | Job triggered in Cloud UI |
| Logs | `run_logs/*.log` | Stored in dbt Cloud UI |
| Docs | `dbt docs serve` locally | Hosted at cloud.getdbt.com |
| CI/CD | Manual | GitHub PR → job trigger |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `+static_analysis` error | Remove it from dbt_project.yml — dbt-core doesn't support it |
| `dataset not found` in Cloud | Check dataset name matches in Cloud environment settings |
| Auth fails in Cloud | Re-upload JSON key in Project → Connections |
| Subdirectory not found | Set `jaffle_shop_cloud` as project subdirectory in repo settings |
