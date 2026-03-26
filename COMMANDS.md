# dbt + DuckDB — Commands Reference

Quick reference for running dbt and querying DuckDB from Git Bash.
Use this for demos and day-to-day work.

---

## Setup

Open **Git Bash** and navigate to the project:

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop
```

---

## dbt Commands

### Build & Run

```bash
# Run everything: seeds + models + tests (start here)
dbt build

# Run only models (no seeds, no tests)
dbt run

# Run only seeds (reload CSVs into raw tables)
dbt seed

# Run only tests
dbt test
```

### Selecting specific models

```bash
# Run one model
dbt run --select customers

# Run all staging models
dbt run --select staging

# Run a model + everything upstream (dependencies)
dbt run --select +orders

# Run a model + everything downstream (dependents)
dbt run --select customers+

# Run a model + both upstream and downstream
dbt run --select +orders+

# Run multiple specific models
dbt run --select stg_orders stg_customers
```

### Inspecting without running

```bash
# List all models, seeds, tests in the project
dbt ls

# Preview top 10 rows from a model
dbt show --select customers
dbt show --select orders
dbt show --select stg_orders

# Preview more rows
dbt show --select customers --limit 50

# See the compiled SQL (Jinja rendered, no execution)
dbt compile --select stg_orders
dbt compile --select customers
```

### Testing

```bash
# Run all tests
dbt test

# Test one model
dbt test --select orders

# Test all staging models
dbt test --select staging
```

### Useful flags

```bash
# See what dbt WOULD run without actually running it (dry run)
dbt run --select +customers --dry-run

# Run with more output detail
dbt run --select customers --show completed
```

---

## DuckDB CLI

> IMPORTANT: Close the DuckDB CLI before running any dbt commands.
> DuckDB locks the entire file — dbt cannot open it while the CLI is connected.

### Connect

```bash
# If duckdb is on your PATH (after restarting Git Bash post-install)
duckdb C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop/jaffle_shop.duckdb

# If duckdb is not on PATH yet (winget install lag)
"/c/Users/kriparam/AppData/Local/Microsoft/WinGet/Packages/DuckDB.cli_Microsoft.Winget.Source_8wekyb3d8bbwe/duckdb.exe" "C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop/jaffle_shop.duckdb"
```

### Explore the database

```sql
-- list all tables in current schema
SHOW TABLES;

-- list tables in all schemas
SELECT table_schema, table_name FROM information_schema.tables ORDER BY 1, 2;

-- describe a table's columns
DESCRIBE main.customers;
DESCRIBE main.orders;
DESCRIBE main_raw.raw_orders;
```

### Query mart tables (transformed data)

```sql
-- top customers by lifetime spend
SELECT customer_name, count_lifetime_orders, lifetime_spend, customer_type
FROM main.customers
ORDER BY lifetime_spend DESC
LIMIT 10;

-- new vs returning customer breakdown
SELECT customer_type, COUNT(*) as count, ROUND(AVG(lifetime_spend), 2) as avg_spend
FROM main.customers
GROUP BY customer_type;

-- orders with food and drink
SELECT order_date, order_total, is_food_order, is_drink_order, count_order_items
FROM main.orders
ORDER BY order_date
LIMIT 20;

-- total revenue by day
SELECT order_date, COUNT(*) as order_count, ROUND(SUM(order_total), 2) as daily_revenue
FROM main.orders
GROUP BY order_date
ORDER BY order_date;

-- top selling products
SELECT product_name, SUM(quantity) as units_sold
FROM main.order_items
GROUP BY product_name
ORDER BY units_sold DESC;
```

### Query raw tables (before transformation)

```sql
-- raw orders — messy column names, amounts in cents, full timestamps
SELECT * FROM main_raw.raw_orders LIMIT 5;

-- raw customers
SELECT * FROM main_raw.raw_customers LIMIT 5;

-- compare raw vs transformed side by side
SELECT
    r.id,
    r.customer       AS raw_customer_col,
    o.customer_id    AS clean_customer_id,
    r.subtotal       AS raw_cents,
    o.subtotal       AS clean_dollars,
    r.ordered_at     AS raw_timestamp,
    o.order_date     AS clean_date
FROM main_raw.raw_orders r
JOIN main.orders o ON r.id = o.order_id
LIMIT 10;
```

### Query staging tables (renamed but not yet joined)

```sql
-- staging orders — renamed columns, cents converted, no joins yet
SELECT * FROM main.stg_orders LIMIT 5;

-- staging customers
SELECT * FROM main.stg_customers LIMIT 5;
```

### Exit

```sql
.quit
```

---

## Workflow reminder

```
1. Run dbt commands    (Git Bash terminal A)
2. Quit DuckDB CLI     (.quit) before running dbt
3. Connect DuckDB CLI  (Git Bash terminal B) to inspect results
4. Quit DuckDB CLI     before running dbt again
```

Never have DuckDB CLI open at the same time as a running dbt command.
