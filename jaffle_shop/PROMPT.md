# jaffle_shop (DuckDB) — Autonomous Setup Prompt

Use this prompt in a new Claude Code conversation inside `dbt-mcp-demo/` to build
the complete jaffle_shop DuckDB project from scratch.

---

## Prompt

I want to build the jaffle_shop dbt project on DuckDB using dbt-fusion. Complete all steps below.

### 1 — Initialize

```bash
dbt init --project-name jaffle_shop --skip-profile-setup --sample jaffle-shop
```

Create `~/.dbt/profiles.yml`:
```yaml
jaffle_shop:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: "C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop/jaffle_shop.duckdb"
      threads: 4
```

### 2 — Install packages and build baseline

```bash
cd jaffle_shop && dbt deps && dbt build
```

Expected: 6 seeds + 6 staging models + tests all pass.

### 3 — Add intermediate layer

Create `models/intermediate/int_orders_enriched.sql`:
- Join `stg_orders` + `stg_customers` + `stg_locations`
- Output: `order_id`, `order_date`, `customer_id`, `customer_name`, `location_id`,
  `location_name`, `tax_rate`, `subtotal`, `tax_paid`, `order_total`

Create `models/intermediate/int_order_items_enriched.sql`:
- Join `stg_order_items` + `stg_products` + supply costs from `stg_supplies` (SUM per product_id)
- Output: `order_item_id`, `order_id`, `product_id`, `product_name`, `product_type`,
  `product_price`, `is_food_item`, `is_drink_item`, `supply_cost`, `gross_margin`

### 4 — Add gold layer

Create `models/marts/dim_customers.sql`:
- Source: `int_orders_enriched`
- Aggregate per customer: `total_orders`, `total_spend` (round 2), `avg_order_value` (round 2),
  `first_order_date`, `last_order_date`, `locations_visited`
- Derive `customer_segment`: Gold (>= $100), Silver (>= $50), Bronze (< $50)

Create `models/marts/fct_orders.sql`:
- Source: `int_orders_enriched` LEFT JOIN item summary from `int_order_items_enriched` (per order_id)
- Item summary: `count_items`, `count_food_items`, `count_drink_items`,
  `total_supply_cost`, `total_gross_margin` (all COALESCE to 0)
- Derive: `is_food_order`, `is_drink_order`
- Derive: `customer_order_number` (ROW_NUMBER PARTITION BY customer_id ORDER BY order_date)

### 5 — Update dbt_project.yml

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

### 6 — Create YAML files with lineage-aware tests

`models/intermediate/_int_jaffle_shop.yml`:
- `int_orders_enriched`: PK `order_id` (unique+not_null), `order_date` (not_null — gap in stg_orders),
  `order_total` (not_null). All pass-through columns: description notes upstream coverage, no test.
- `int_order_items_enriched`: PK `order_item_id` (unique+not_null), `product_price` (not_null),
  `gross_margin` (not_null). Pass-throughs: note upstream coverage.

`models/marts/_gold_jaffle_shop.yml`:
- `dim_customers`: PK `customer_id` (unique+not_null), not_null on all metrics,
  `accepted_values` on `customer_segment` using `arguments:` wrapper.
- `fct_orders`: PK `order_id` (unique+not_null), not_null on `customer_id`, `order_total`,
  `count_items`, `count_food_items`, `count_drink_items`, `total_gross_margin`, `customer_order_number`.
  Pass-throughs noted. `fct_orders.order_date` skipped — covered at int layer.

> dbt-fusion: all generic tests require the `arguments:` wrapper:
> ```yaml
> - accepted_values:
>     arguments:
>       values: ['Gold', 'Silver', 'Bronze']
> ```

### 7 — Build and verify

```bash
dbt build
dbt test --select intermediate marts
dbt show --select fct_orders
dbt show --select dim_customers
```

Expected: 41 tests pass (39 schema + 2 unit tests).

### 8 — Install agent skills

```bash
mkdir -p .claude/commands
for skill in running-dbt-commands using-dbt-for-analytics-engineering troubleshooting-dbt-job-errors \
             configuring-dbt-mcp-server adding-dbt-unit-test fetching-dbt-docs \
             answering-natural-language-questions-with-dbt building-dbt-semantic-layer; do
  curl -s "https://raw.githubusercontent.com/dbt-labs/dbt-agent-skills/main/skills/dbt/skills/${skill}/SKILL.md" \
    -o ".claude/commands/${skill}.md"
done
```

---

## Success criteria
- `dbt build` passes — 6 seeds, 14+ models, 41 tests
- `dim_customers` has rows with `customer_segment` in Gold/Silver/Bronze
- `fct_orders` has non-null `total_gross_margin` and `customer_order_number`
- `.claude/commands/` has 8 skill files
