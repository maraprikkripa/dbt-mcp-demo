# jaffle_shop_bq — BigQuery Commands Reference

**Project dir:** `dbt-mcp-demo/jaffle_shop_bq/`
**Warehouse:** BigQuery — `bespin-us-demo.jaffle_shop_fusion`
**Shell:** Git Bash

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop_bq
```

---

## dbt — Build & Run

```bash
dbt build                              # seeds + models + tests (full run)
dbt seed                               # load CSVs into jaffle_shop_fusion_raw dataset
dbt run                                # run all models
dbt test                               # run all tests
dbt deps                               # install packages (dbt_utils)
```

## dbt — Layer by layer (demo workflow)

```bash
dbt seed                               # Step 1 — load raw tables into BigQuery
dbt run --select staging               # Step 2 — staging views
dbt run --select intermediate          # Step 3 — intermediate views
dbt run --select marts                 # Step 4 — gold tables
dbt test --select intermediate marts   # Step 5 — run tests
```

## dbt — Show data at each layer

```bash
# Staging (renamed + cast)
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
dbt test --select intermediate marts   # two folders
dbt compile --select stg_orders        # see rendered SQL
dbt ls                                 # list all nodes
```

## Debug & connection check

```bash
dbt debug                              # verify BigQuery connection + profile
dbt compile --select fct_orders        # render SQL without running
```

---

## BigQuery Console queries

Open: console.cloud.google.com → BigQuery → bespin-us-demo

### Demo queries — raw vs transformed

```sql
-- Raw orders (cents, messy column names)
SELECT * FROM `bespin-us-demo.jaffle_shop_fusion_raw.raw_orders` LIMIT 5;

-- Staging orders (dollars, renamed columns)
SELECT * FROM `bespin-us-demo.jaffle_shop_fusion.stg_orders` LIMIT 5;

-- Before vs after transformation side by side
SELECT
    r.id,
    r.subtotal       AS raw_cents,
    o.subtotal       AS clean_dollars,
    r.ordered_at     AS raw_timestamp,
    o.order_date     AS clean_date
FROM `bespin-us-demo.jaffle_shop_fusion_raw.raw_orders` r
JOIN `bespin-us-demo.jaffle_shop_fusion.stg_orders` o ON r.id = o.order_id
LIMIT 10;

-- Intermediate (customer + location joined in)
SELECT order_id, order_date, customer_name, location_name, order_total
FROM `bespin-us-demo.jaffle_shop_fusion.int_orders_enriched`
LIMIT 10;

-- Gold: fct_orders
SELECT order_id, order_date, customer_name, location_name,
       order_total, count_items, total_gross_margin, customer_order_number
FROM `bespin-us-demo.jaffle_shop_fusion.fct_orders`
ORDER BY order_date LIMIT 10;

-- Gold: dim_customers — top spenders
SELECT customer_name, total_orders, total_spend, customer_segment
FROM `bespin-us-demo.jaffle_shop_fusion.dim_customers`
ORDER BY total_spend DESC LIMIT 10;

-- Segment breakdown
SELECT customer_segment, COUNT(*) as customers, ROUND(AVG(total_spend), 2) as avg_spend
FROM `bespin-us-demo.jaffle_shop_fusion.dim_customers`
GROUP BY customer_segment ORDER BY 1;

-- Revenue by location
SELECT location_name, COUNT(*) as orders, ROUND(SUM(order_total), 2) as revenue
FROM `bespin-us-demo.jaffle_shop_fusion.fct_orders`
GROUP BY location_name ORDER BY revenue DESC;
```

---

## No file locking on BigQuery
Unlike DuckDB, BigQuery is serverless — multiple processes can read/write simultaneously.
No need to close any client before running dbt.
