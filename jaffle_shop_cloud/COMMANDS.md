# jaffle_shop_cloud — dbt Cloud + BigQuery Commands Reference

**Project dir:** `dbt-mcp-demo/jaffle_shop_cloud/`
**Platform:** dbt Cloud → BigQuery (`bespin-us-demo.jaffle_shop_cloud`)

---

## Local development (dbt-fusion against jaffle_shop_cloud dataset)

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop_cloud
```

```bash
dbt debug                              # verify BigQuery connection
dbt deps                               # install packages
dbt build                              # seeds + models + tests
dbt seed                               # load CSVs into jaffle_shop_cloud_raw
dbt run                                # run all models
dbt test                               # run all tests
```

## Local demo workflow — layer by layer

```bash
dbt seed                               # Step 1 — raw tables in BigQuery
dbt run --select staging               # Step 2 — staging views
dbt run --select intermediate          # Step 3 — intermediate views
dbt run --select marts                 # Step 4 — gold tables
dbt test --select intermediate marts   # Step 5 — tests
```

## Local show commands

```bash
dbt show --select raw_orders           # raw: cents, messy names
dbt show --select stg_orders           # staging: dollars, renamed
dbt show --select int_orders_enriched  # intermediate: names joined in
dbt show --select fct_orders           # gold: item counts, margins
dbt show --select dim_customers        # gold: segments
```

## With logging

```bash
dbt build 2>&1 | tee run_logs/build_$(date +%Y%m%d_%H%M%S).log
dbt test 2>&1 | tee run_logs/test_$(date +%Y%m%d_%H%M%S).log
```

---

## dbt Cloud — trigger runs from CLI

```bash
# Trigger a job run via dbt Cloud API (replace JOB_ID and TOKEN)
curl -X POST \
  -H "Authorization: Token $DBT_CLOUD_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"cause": "manual trigger"}' \
  "https://cloud.getdbt.com/api/v2/accounts/{ACCOUNT_ID}/jobs/{JOB_ID}/run/"
```

---

## BigQuery Console queries

Open: console.cloud.google.com → BigQuery → bespin-us-demo

```sql
-- Row count health check across all layers
SELECT 'raw_orders'           AS layer, COUNT(*) AS rows FROM `bespin-us-demo.jaffle_shop_cloud_raw.raw_orders`
UNION ALL
SELECT 'stg_orders',           COUNT(*) FROM `bespin-us-demo.jaffle_shop_cloud.stg_orders`
UNION ALL
SELECT 'int_orders_enriched',  COUNT(*) FROM `bespin-us-demo.jaffle_shop_cloud.int_orders_enriched`
UNION ALL
SELECT 'fct_orders',           COUNT(*) FROM `bespin-us-demo.jaffle_shop_cloud.fct_orders`
UNION ALL
SELECT 'dim_customers',        COUNT(*) FROM `bespin-us-demo.jaffle_shop_cloud.dim_customers`
ORDER BY layer;

-- Top customers
SELECT customer_name, total_orders, total_spend, customer_segment
FROM `bespin-us-demo.jaffle_shop_cloud.dim_customers`
ORDER BY total_spend DESC LIMIT 10;

-- Segment breakdown
SELECT customer_segment, COUNT(*) AS customers, ROUND(AVG(total_spend),2) AS avg_spend
FROM `bespin-us-demo.jaffle_shop_cloud.dim_customers`
GROUP BY customer_segment ORDER BY 1;

-- Revenue by location
SELECT location_name, COUNT(*) AS orders, ROUND(SUM(order_total),2) AS revenue
FROM `bespin-us-demo.jaffle_shop_cloud.fct_orders`
GROUP BY location_name ORDER BY revenue DESC;
```
