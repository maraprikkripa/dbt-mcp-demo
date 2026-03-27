# dbt Cloud Build Fixes — jaffle_shop_cloud

## Error: Invalid date: '2016-09-01 07:29:00.000'

### Where it appeared

Two failures in the Staging Build job:

```
[ERROR]: in model order_items (models/marts/order_items.sql)
  Database Error: Invalid date: '2016-09-01 07:29:00.000'

[ERROR]: in test not_null_int_orders_enriched_order_date
  Database Error: Invalid date: '2016-09-01 07:29:00.000'
  while executing the filter on column 'ORDERED_AT'
```

---

### Root cause

**dbt-fusion** (used locally for DuckDB and BigQuery dev) auto-detects CSV column types
when loading seeds. It reads `ordered_at` values like `2016-09-01 07:29:00.000` and
automatically loads them as `TIMESTAMP`.

**dbt-core** (used by dbt Cloud) loads ALL seed columns as `STRING` by default.
When `stg_orders.sql` runs `CAST(ordered_at AS DATE)` in BigQuery, it receives a
full timestamp string `'2016-09-01 07:29:00.000'` — BigQuery cannot cast a string
with a time component directly to DATE.

```
dbt-fusion:  ordered_at → TIMESTAMP → CAST(TIMESTAMP AS DATE) ✓
dbt-core:    ordered_at → STRING    → CAST(STRING AS DATE)    ✗
```

---

### Fix

Added `+column_types` to `dbt_project.yml` to explicitly tell dbt-core to load
the timestamp columns as `TIMESTAMP` instead of `STRING`.

**File:** `jaffle_shop_cloud/dbt_project.yml`

```yaml
seeds:
  jaffle_shop_cloud:
    +schema: raw
    raw_orders:
      +column_types:
        ORDERED_AT: timestamp     # CSV header is uppercase — must match exactly
    raw_stores:
      +column_types:
        opened_at: timestamp      # CSV header is lowercase
```

---

### Why `ORDERED_AT` is uppercase

The `raw_orders.csv` header row uses uppercase column names:

```
ID,CUSTOMER,ORDERED_AT,STORE_ID,SUBTOTAL,TAX_PAID,ORDER_TOTAL
```

dbt's `+column_types` lookup is **case-sensitive** — the key must exactly match the
CSV header. Using `ordered_at` (lowercase) produced a silent warning and was ignored:

```
[WARNING]: Column types specified for non-existent columns in seed 'raw_orders':
ordered_at. These column type overrides will be ignored.
```

`raw_stores.csv` uses lowercase headers (`id,name,opened_at,tax_rate`) so `opened_at`
works without capitalisation.

---

### Why `--full-refresh` was needed

Seeds already existed in BigQuery from a previous failed run (loaded as `STRING`).
A normal `dbt build` truncates and re-inserts data without changing the table schema.
Running `dbt build --full-refresh` forces dbt to **drop and recreate** the seed tables,
applying the new `column_types` definition.

After the first successful run with the fix in place, subsequent runs (`dbt build`
without `--full-refresh`) will work correctly because the schema is already correct.

---

### Commits

| Commit | Branch | Change |
|---|---|---|
| `29c482b` | `stg` | Added `+column_types` with lowercase `ordered_at` (not yet working) |
| `e479294` | `stg` | Fixed case to `ORDERED_AT` to match CSV header — resolves the error |
