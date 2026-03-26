# jaffle_shop — DuckDB Commands Reference

**Project dir:** `dbt-mcp-demo/jaffle_shop/`
**Shell:** Git Bash

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop
```

---

## dbt — Build & Run

```bash
dbt build                              # seeds + models + tests (full run)
dbt seed                               # load CSVs into main_raw schema
dbt run                                # run all models
dbt test                               # run all tests
dbt deps                               # install packages (dbt_utils)
```

## dbt — Layer by layer (demo workflow)

```bash
dbt seed                               # Step 1 — load raw data
dbt run --select staging               # Step 2 — staging views
dbt run --select intermediate          # Step 3 — intermediate views
dbt run --select marts                 # Step 4 — gold tables
dbt test --select intermediate marts   # Step 5 — run tests
```

## dbt — Show data at each layer

```bash
# Raw (before transformation)
dbt show --select source:ecom.raw_orders
dbt show --select source:ecom.raw_customers

# Staging (renamed + cast, no joins)
dbt show --select stg_orders
dbt show --select stg_customers

# Intermediate (joined, enriched)
dbt show --select int_orders_enriched
dbt show --select int_order_items_enriched

# Gold (aggregated, segmented)
dbt show --select fct_orders
dbt show --select dim_customers
dbt show --select fct_orders --limit 20
```

## dbt — Select syntax

```bash
dbt run --select orders                # one model
dbt run --select staging               # entire folder
dbt run --select +fct_orders           # model + all upstream
dbt run --select fct_orders+           # model + all downstream
dbt test --select intermediate marts   # two folders
dbt compile --select stg_orders        # see rendered SQL
dbt ls                                 # list all nodes
dbt ls --resource-type model           # list models only
```

---

## DuckDB CLI

> IMPORTANT: `.quit` before running any dbt command — DuckDB locks the entire file.

```bash
# Connect
duckdb C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop/jaffle_shop.duckdb

# Explore
SHOW TABLES;
SELECT table_schema, table_name FROM information_schema.tables ORDER BY 1,2;
DESCRIBE main.fct_orders;
```

### Demo queries — raw vs transformed

```sql
-- Raw orders (cents, messy column names)
SELECT * FROM main_raw.raw_orders LIMIT 5;

-- Staging orders (dollars, renamed columns, no joins)
SELECT * FROM main.stg_orders LIMIT 5;

-- Intermediate (customer + location joined in)
SELECT order_id, order_date, customer_name, location_name, order_total
FROM main.int_orders_enriched LIMIT 10;

-- Gold: fct_orders (item counts + gross margin)
SELECT order_id, order_date, customer_name, location_name,
       order_total, count_items, total_gross_margin, customer_order_number
FROM main.fct_orders LIMIT 10;

-- Gold: dim_customers (lifetime metrics + segment)
SELECT customer_name, total_orders, total_spend, customer_segment
FROM main.dim_customers
ORDER BY total_spend DESC LIMIT 10;

-- Segment breakdown
SELECT customer_segment, COUNT(*) as customers, ROUND(AVG(total_spend),2) as avg_spend
FROM main.dim_customers
GROUP BY customer_segment ORDER BY 1;

-- Before vs after transformation
SELECT r.id, r.subtotal AS raw_cents, o.subtotal AS clean_dollars,
       r.ordered_at AS raw_timestamp, o.order_date AS clean_date
FROM main_raw.raw_orders r
JOIN main.stg_orders o ON r.id = o.order_id LIMIT 10;

.quit
```
