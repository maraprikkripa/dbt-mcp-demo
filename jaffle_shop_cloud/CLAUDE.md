# jaffle_shop_cloud — dbt Cloud + BigQuery Project

## Runtime
- **Platform:** dbt Cloud (cloud.getdbt.com) — runs in the cloud, not locally
- **Adapter:** dbt-core with BigQuery adapter (managed by dbt Cloud)
- **Warehouse:** Google BigQuery — project `bespin-us-demo`
- **Dataset:** `jaffle_shop_cloud` (dev target)
- **Auth:** Service account JSON key (uploaded to dbt Cloud connection settings)
- **Profile:** `jaffle_shop_cloud` in `~/.dbt/profiles.yml` (local dev only)
- **Code source:** GitHub → `maraprikkripa/dbt-mcp-demo` → subdirectory `jaffle_shop_cloud/`
- **Project dir:** `dbt-mcp-demo/jaffle_shop_cloud/`

## How dbt Cloud differs from dbt-fusion

| Aspect | dbt-fusion (local) | dbt Cloud |
|---|---|---|
| Where it runs | Your machine | dbt Cloud servers |
| Code source | Local files | GitHub repo |
| Auth | Local keyfile path | Key uploaded to Cloud UI |
| profiles.yml | Required locally | Not used in Cloud runs |
| Scheduling | Manual | Jobs with cron schedules |
| Docs | `dbt docs generate` locally | Hosted automatically |
| IDE | VS Code / Claude Code | dbt Cloud IDE (browser) |
| `+static_analysis` | dbt-fusion only | Remove — not supported |

## Architecture — 4-layer model

```
Seeds (jaffle_shop_cloud_raw dataset)
  →  Staging (views, jaffle_shop_cloud dataset)
  →  Intermediate (views, jaffle_shop_cloud dataset)
  →  Marts/Gold (tables, jaffle_shop_cloud dataset)
```

## Naming conventions
- Staging: `stg_<entity>.sql`
- Intermediate: `int_<topic>_<verb>.sql`
- Dimension: `dim_<entity>.sql`
- Fact: `fct_<event>.sql`
- YAML per folder: `_<layer>_jaffle_shop.yml`

## Testing — lineage-aware rules
Same as other projects. dbt Cloud runs `dbt test` as part of jobs.
No `arguments:` wrapper needed — dbt-core uses standard YAML syntax:
```yaml
- accepted_values:
    values: ['Gold', 'Silver', 'Bronze']
```
But since we use dbt-fusion locally too, keep `arguments:` wrapper for compatibility.

## BigQuery datasets
- `jaffle_shop_cloud` — staging + intermediate + mart models
- `jaffle_shop_cloud_raw` — seeds (auto-created via `+schema: raw`)

## Key notes
- Never commit `keys/` folder — service account key stays local
- dbt Cloud uses its own BigQuery connection — keyfile path not needed in Cloud
- GitHub push triggers are optional — jobs can be run manually or on schedule
- `+static_analysis: strict` removed from dbt_project.yml — dbt-core doesn't support it
