# jaffle_shop — DuckDB Project

## Runtime
- **Adapter:** dbt-fusion (built-in DuckDB, no separate install)
- **Database:** `jaffle_shop.duckdb` (local file, single-user)
- **Profile:** `jaffle_shop` in `~/.dbt/profiles.yml`
- **Project dir:** `dbt-mcp-demo/jaffle_shop/`

## Architecture — 4-layer model

```
Seeds (main_raw schema)  →  Staging (views, main schema)
  →  Intermediate (views, main schema)  →  Marts/Gold (tables, main schema)
```

| Layer | Folder | Materialization | Schema |
|---|---|---|---|
| Seeds | `seeds/` | tables | `main_raw` |
| Staging | `models/staging/` | view | `main` |
| Intermediate | `models/intermediate/` | view | `main` |
| Marts | `models/marts/` | table | `main` |

## Naming conventions
- Staging: `stg_<entity>.sql`
- Intermediate: `int_<topic>_<verb>.sql`
- Dimension: `dim_<entity>.sql`
- Fact: `fct_<event>.sql`
- YAML per folder: `_<layer>_jaffle_shop.yml`

## Testing — lineage-aware rules
1. PKs: always `unique` + `not_null`
2. FKs: `not_null` at first join layer only; skip downstream
3. Pass-throughs: skip if already tested upstream — note in description: `"Not re-tested — already covered upstream."`
4. Computed/derived columns: `not_null` on key metrics
5. Enumerations: `accepted_values`
6. dbt-fusion requires `arguments:` wrapper on all generic tests

## DuckDB file locking
DuckDB locks the entire `.duckdb` file per connection.
- Close DuckDB CLI (`.quit`) before running any dbt command
- Never have CLI open at the same time as `dbt run/build/test`

## Key quirks
- Amounts in raw seeds are in **cents** — `cents_to_dollars()` macro converts in staging
- `+schema: raw` in `dbt_project.yml` means seeds land in `main_raw`, models in `main`
- dbt-fusion warnings about `--warn-error-options` and `--use-colors` are harmless

## MCP tools (use instead of Bash for dbt)
`dbt_build` · `dbt_run` · `dbt_test` · `dbt_seed` · `dbt_compile` · `dbt_show` · `dbt_list`
