# jaffle_shop_bq — BigQuery Project

## Runtime
- **Adapter:** dbt-fusion (built-in BigQuery support)
- **Warehouse:** Google BigQuery — project `bespin-us-demo`
- **Dataset:** `jaffle_shop_fusion` (dev target)
- **Auth:** Service account JSON key
- **Profile:** `jaffle_shop_bq` in `~/.dbt/profiles.yml`
- **Project dir:** `dbt-mcp-demo/jaffle_shop_bq/`

## Architecture — 4-layer model

```
Seeds (jaffle_shop_fusion_raw dataset)
  →  Staging (views, jaffle_shop_fusion dataset)
  →  Intermediate (views, jaffle_shop_fusion dataset)
  →  Marts/Gold (tables, jaffle_shop_fusion dataset)
```

| Layer | Folder | Materialization | BigQuery dataset |
|---|---|---|---|
| Seeds | `seeds/` | tables | `jaffle_shop_fusion_raw` |
| Staging | `models/staging/` | view | `jaffle_shop_fusion` |
| Intermediate | `models/intermediate/` | view | `jaffle_shop_fusion` |
| Marts | `models/marts/` | table | `jaffle_shop_fusion` |

## Naming conventions
Same as DuckDB project:
- Staging: `stg_<entity>.sql`
- Intermediate: `int_<topic>_<verb>.sql`
- Dimension: `dim_<entity>.sql`
- Fact: `fct_<event>.sql`
- YAML per folder: `_<layer>_jaffle_shop.yml`

## Testing — lineage-aware rules
Same as DuckDB project — see DuckDB project CLAUDE.md for full rules.
No `arguments:` wrapper needed on BigQuery (dbt-core syntax) — but dbt-fusion still requires it.

## BigQuery-specific notes
- No file locking — multiple processes can run simultaneously
- Seeds land in `<dataset>_raw` schema due to `+schema: raw` in dbt_project.yml
- `dbt show` queries BigQuery live — requires active credentials
- Service account key at: `C:/Users/kriparam/Documents/dbt-mcp-demo/keys/bespin-us-demo-3ab1ffe14924.json`
- **Never commit the keys/ folder** — it is in .gitignore
- Amounts in raw seeds are in **cents** — `cents_to_dollars()` macro converts in staging

## Key differences vs DuckDB project
| Aspect | DuckDB | BigQuery |
|---|---|---|
| File locking | Yes — close CLI first | No — concurrent access fine |
| Query results | Instant (local) | Seconds (network round-trip) |
| Cost | Free | BigQuery free tier: 1TB queries/month |
| Auth | None needed | Service account JSON key |
| Schema | `main` / `main_raw` | `jaffle_shop_fusion` / `jaffle_shop_fusion_raw` |

## MCP tools (use instead of Bash for dbt)
`dbt_build` · `dbt_run` · `dbt_test` · `dbt_seed` · `dbt_compile` · `dbt_show` · `dbt_list`
