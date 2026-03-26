# jaffle_shop — DuckDB Setup Guide

**Runtime:** dbt-fusion · **Database:** DuckDB · **Project:** jaffle_shop

---

## Prerequisites

```bash
python --version    # 3.10+
uv --version        # Python package manager
dbt --version       # dbt-fusion 2.x
duckdb --version    # DuckDB CLI (for querying — optional)
```

Install dbt-fusion if missing:
```bash
# Windows — download from https://docs.getdbt.com/docs/dbt-versions/core-upgrade
```

---

## Step 1 — Initialize the project

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo
dbt init --project-name jaffle_shop --skip-profile-setup --sample jaffle-shop
cd jaffle_shop
```

## Step 2 — Create ~/.dbt/profiles.yml

```yaml
jaffle_shop:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: "C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop/jaffle_shop.duckdb"
      threads: 4
```

## Step 3 — Install packages

```bash
dbt deps
```

## Step 4 — Add intermediate + gold layer models

Create `models/intermediate/int_orders_enriched.sql`:
```sql
with orders as (select * from {{ ref('stg_orders') }}),
customers as (select * from {{ ref('stg_customers') }}),
locations as (select * from {{ ref('stg_locations') }})
select
    orders.order_id, orders.order_date, orders.customer_id,
    customers.customer_name, orders.location_id, locations.location_name,
    locations.tax_rate, orders.subtotal, orders.tax_paid, orders.order_total
from orders
left join customers on orders.customer_id = customers.customer_id
left join locations on orders.location_id = locations.location_id
```

Create `models/intermediate/int_order_items_enriched.sql`:
```sql
with order_items as (select * from {{ ref('stg_order_items') }}),
products as (select * from {{ ref('stg_products') }}),
supply_costs as (
    select product_id, sum(supply_cost) as total_supply_cost
    from {{ ref('stg_supplies') }} group by product_id
)
select
    order_items.order_item_id, order_items.order_id, order_items.product_id,
    products.product_name, products.product_type, products.product_price,
    products.is_food_item, products.is_drink_item,
    coalesce(supply_costs.total_supply_cost, 0) as supply_cost,
    products.product_price - coalesce(supply_costs.total_supply_cost, 0) as gross_margin
from order_items
left join products on order_items.product_id = products.product_id
left join supply_costs on order_items.product_id = supply_costs.product_id
```

Create `models/marts/dim_customers.sql` and `models/marts/fct_orders.sql` — see PROMPT.md for full SQL.

## Step 5 — Update dbt_project.yml

```yaml
models:
  jaffle_shop:
    +static_analysis: strict
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    marts:
      +materialized: table
```

## Step 6 — Build

```bash
dbt build
```

Expected: 6 seeds + 12+ models + 41 tests — all pass.

## Step 7 — Verify

```bash
dbt show --select fct_orders
dbt show --select dim_customers
dbt test --select intermediate marts
```

## Step 8 — Install dbt agent skills

```bash
mkdir -p .claude/commands
SKILLS=(running-dbt-commands using-dbt-for-analytics-engineering troubleshooting-dbt-job-errors
        configuring-dbt-mcp-server adding-dbt-unit-test fetching-dbt-docs
        answering-natural-language-questions-with-dbt building-dbt-semantic-layer)
for skill in "${SKILLS[@]}"; do
  curl -s "https://raw.githubusercontent.com/dbt-labs/dbt-agent-skills/main/skills/dbt/skills/${skill}/SKILL.md" \
    -o ".claude/commands/${skill}.md"
done
```

## Step 9 — Configure MCP server

From workspace root `dbt-mcp-demo/`:
```bash
claude mcp add dbt -s project \
  -e DBT_PROJECT_DIR="C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop" \
  -e DBT_PATH="C:/Users/kriparam/.local/bin/dbt.exe" \
  -- uvx dbt-mcp
```

Edit `.mcp.json` to add: `"DISABLE_SEMANTIC_LAYER": "true"` and `"DISABLE_DISCOVERY_API": "true"`.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `dbt: command not found` | Check `which dbt`, add `~/.local/bin` to PATH |
| `profile not found` | Run `dbt debug` to see what profile it expects |
| `file in use` error | Close DuckDB CLI (`.quit`) then retry |
| MCP tools not showing | Restart Claude Code, check forward slashes in paths |
