# dbt Project Conventions — jaffle_shop

## Project overview

This is the jaffle_shop dbt project — a fictional coffee shop dataset used as a demo for
dbt agentic development. It runs on DuckDB locally (via dbt-fusion) and connects to Claude Code
via the dbt MCP server.

Working directory: `dbt-mcp-demo/`
dbt project root: `dbt-mcp-demo/jaffle_shop/`

---

## Architecture — 4-layer data model

```
Seeds (raw CSVs loaded into main_raw schema)
  └─► Staging (views — rename and cast raw columns, no business logic)
        └─► Intermediate (views — joins across domains, one topic per model)
              └─► Marts / Gold (tables — aggregations, business logic, analytics-ready)
```

| Layer | Folder | Materialization | Purpose |
|---|---|---|---|
| Seeds | `seeds/` | tables in `main_raw` schema | Raw source data (CSVs) |
| Staging | `models/staging/` | view | Rename, cast, clean — no logic |
| Intermediate | `models/intermediate/` | view | Join staging models, enrich |
| Marts | `models/marts/` | table | Aggregations, segments, fact/dim tables |

---

## Naming conventions

- **Staging models:** `stg_<entity>.sql` — one model per source table
- **Intermediate models:** `int_<topic>_<verb>.sql` — e.g. `int_orders_enriched`
- **Dimension models:** `dim_<entity>.sql` — one record per entity
- **Fact models:** `fct_<event>.sql` — one record per event/transaction
- **YAML files:** `_<layer>_jaffle_shop.yml` per folder — e.g. `_int_jaffle_shop.yml`
- **Sources:** declared in `models/staging/__sources.yml`

---

## Testing philosophy — lineage-aware

**Do not re-test columns already tested upstream.** Before adding a test, check whether the
column is a pass-through from a staging model that already has coverage.

Rules:
1. **Primary keys** — always test `unique` + `not_null` on every model's PK
2. **Foreign keys** — test `not_null` at the layer where the join first happens; skip downstream
3. **Pass-through columns** — if `customer_id` is tested not_null in `stg_orders`, do not
   repeat the test in `int_orders_enriched` or `fct_orders`
4. **Derived/computed columns** — test `not_null` on key metrics (`order_total`, `total_gross_margin`)
5. **Categorical columns** — use `accepted_values` on enumerations (`customer_segment`)

Document the lineage decision in the column description:
```yaml
- name: customer_id
  description: "Foreign key to stg_customers. Not re-tested — already covered upstream."
```

---

## dbt-fusion notes (local DuckDB)

- Run with `--compute inline` flag or omit (inline is the default for dbt-fusion)
- Two schemas in one `.duckdb` file: `main_raw` (seeds), `main` (models)
- DuckDB locks the entire file — close any open DuckDB CLI session before running dbt
- `accepted_values` and other generic tests require the `arguments:` wrapper:

```yaml
- accepted_values:
    arguments:
      values: ['Gold', 'Silver', 'Bronze']
```

---

## MCP tools available

| Tool | What it does |
|---|---|
| `dbt_build` | Run seeds + models + tests in dependency order |
| `dbt_run` | Run models only (with optional `--select`) |
| `dbt_test` | Run tests only |
| `dbt_compile` | Render SQL without executing |
| `dbt_show` | Preview rows from a model |
| `dbt_list` | List models, seeds, tests in the project |

Always use MCP tools to run dbt commands — do not use the Bash tool for dbt.

---

## Key source columns (raw seeds)

| Seed | Key columns |
|---|---|
| `raw_customers` | `id`, `name` |
| `raw_orders` | `id`, `customer`, `ordered_at`, `store_id`, `subtotal`, `tax_paid`, `order_total` (cents) |
| `raw_items` | `id`, `order_id`, `sku` |
| `raw_products` | `sku`, `name`, `type`, `price`, `description` |
| `raw_stores` | `id`, `name`, `opened_at`, `tax_rate` |
| `raw_supplies` | `id`, `name`, `cost`, `perishable`, `sku` |

Amounts in raw seeds are in **cents** — staging models convert to dollars via the
`cents_to_dollars()` macro.
