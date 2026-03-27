# New dbt + BigQuery Project — Autonomous Build Prompt

Copy everything below the line and paste it into a new Claude Code conversation
opened inside `dbt-mcp-demo/`.

---

## THE PROMPT

I want to build a complete dbt project on BigQuery using dbt-fusion. Work through
every step below autonomously. Do not stop to ask questions — use the values
provided. If a step fails, diagnose and fix it before moving on.

Use the /using-dbt-for-analytics-engineering skill for all model building,
testing, and lineage audit work.
Use the /troubleshooting-dbt-job-errors skill if any build or test fails.

---

### Environment

| Setting | Value |
|---|---|
| GCP project | `bespin-us-demo` |
| BQ dataset (models) | `jaffle_shop_fusion` |
| BQ dataset (seeds) | `jaffle_shop_fusion_raw` |
| Key file | `C:/Users/kriparam/Documents/dbt-mcp-demo/keys/bespin-us-demo-3ab1ffe14924.json` |
| dbt project dir | `C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop_bq` |
| dbt binary | `C:/Users/kriparam/.local/bin/dbt.exe` |
| Profile name | `jaffle_shop_bq` |

---

### Step 1 — Verify connection

From inside `jaffle_shop_bq/`, run `dbt debug`. Must show `All checks passed`.
If it fails, check the keyfile path and profiles.yml.

---

### Step 2 — Install packages

Run `dbt deps` from inside `jaffle_shop_bq/`.

---

### Step 3 — Build everything

Run `dbt build` from inside `jaffle_shop_bq/`.

Expected:
- 6 seeds loaded into `jaffle_shop_fusion_raw`
- 6 staging views + 2 intermediate views + 6 mart tables in `jaffle_shop_fusion`
- All tests pass, 0 errors

If any model fails, fix it and re-run `dbt build --select <failed_model>+`.

---

### Step 4 — Show data at each layer

Run each show command and display the results with a one-line explanation of
what the layer is doing.

**Raw (seeds) — cents amounts, raw column names**
```
dbt show --select raw_orders --limit 5
dbt show --select raw_customers --limit 5
```

**Staging — renamed columns, dollars not cents, no business logic**
```
dbt show --select stg_orders --limit 5
dbt show --select stg_customers --limit 5
```

**Intermediate — joins across domains, derived columns**
```
dbt show --select int_orders_enriched --limit 5
dbt show --select int_order_items_enriched --limit 5
```

**Gold (marts) — aggregations, segments, analytics-ready**
```
dbt show --select dim_customers --limit 10
dbt show --select fct_orders --limit 10
```

---

### Step 5 — Lineage-aware test audit

#### 5a — Build the upstream coverage map

Read all 6 staging YAML files and build this table:

| Staging model | Columns already tested |
|---|---|
| `stg_customers` | `customer_id` (unique, not_null) |
| `stg_orders` | `order_id` (unique, not_null); expression: `order_total - tax_paid = subtotal` |
| `stg_order_items` | `order_item_id` (unique, not_null); `order_id` (not_null, relationship) |
| `stg_products` | `product_id` (unique, not_null) |
| `stg_locations` | `location_id` (unique, not_null); unit test for date truncation |
| `stg_supplies` | `supply_uuid` (unique, not_null) |

#### 5b — Trace every column in intermediate + mart models

For each column, decide:
- **PK** → test unique + not_null
- **FK pointing to a tested PK** → skip, note "Not re-tested — already covered upstream"
- **Pass-through already tested in staging** → skip, note it
- **Derived / computed column** → test not_null
- **Enum / categorical** → test accepted_values
- **COALESCE-protected** → always not_null by construction, no test needed

Known genuine gaps to fill:
- `int_orders_enriched.order_date` — stg_orders does not test this column
- Any other gaps you find while reading the YAML files

#### 5c — Confirm tests are in place for all genuine gaps

Read `_int_jaffle_shop.yml` and `_gold_jaffle_shop.yml`. Confirm the following
tests exist. Add any that are missing.

`int_orders_enriched`: `order_id` (unique, not_null), `order_date` (not_null),
`order_total` (not_null)

`int_order_items_enriched`: `order_item_id` (unique, not_null),
`product_price` (not_null), `gross_margin` (not_null)

`dim_customers`: `customer_id` (unique, not_null), `customer_name` /
`total_orders` / `total_spend` / `avg_order_value` / `first_order_date` /
`last_order_date` / `locations_visited` (all not_null),
`customer_segment` (accepted_values: Gold, Silver, Bronze)

`fct_orders`: `order_id` (unique, not_null), `customer_id` (not_null),
`order_total` / `count_items` / `count_food_items` / `count_drink_items` /
`total_gross_margin` / `customer_order_number` (all not_null)

Note: dbt-fusion requires the `arguments:` wrapper for accepted_values:
```yaml
- accepted_values:
    arguments:
      values: ['Gold', 'Silver', 'Bronze']
```

#### 5d — Run tests and confirm all pass

```
dbt test --select intermediate marts
```

Expected: 41 tests pass, 0 failures.

---

### Step 6 — Business verification queries

Use `dbt show` to answer these questions and summarise the results:

**Customer segments — how many customers in each tier?**
```
dbt show --select dim_customers --limit 200
```
Summarise: count of Gold / Silver / Bronze customers.

**Top 10 customers by lifetime spend**
```
dbt show --select dim_customers --limit 10
```
Show: customer_name, total_spend, total_orders, customer_segment — sorted by total_spend desc.

**Revenue by location**
```
dbt show --select fct_orders --limit 500
```
Summarise: total order_total per location_name.

**Order mix — food vs drink**
```
dbt show --select fct_orders --limit 500
```
Summarise: count of is_food_order = true, is_drink_order = true, both.

**Gross margin check — confirm no nulls**
```
dbt show --select fct_orders --limit 10
```
Confirm total_gross_margin is non-null for all rows shown.

---

### Step 7 — Update .mcp.json

Read `dbt-mcp-demo/.mcp.json`. Add the `dbt-bq` server entry if it does not
already exist:

```json
"dbt-bq": {
  "type": "stdio",
  "command": "uvx",
  "args": ["dbt-mcp"],
  "env": {
    "DBT_PROJECT_DIR": "C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop_bq",
    "DBT_PATH": "C:/Users/kriparam/.local/bin/dbt.exe",
    "DISABLE_SEMANTIC_LAYER": "true",
    "DISABLE_DISCOVERY_API": "true"
  }
}
```

---

### Success criteria — confirm each before finishing

- [ ] `dbt debug` passed — All checks passed
- [ ] `dbt build` passed — 6 seeds, 14 models, 0 errors
- [ ] Data shown at all 4 layers (raw → staging → intermediate → gold)
- [ ] Lineage audit complete — upstream coverage map built, all gaps addressed
- [ ] `dbt test --select intermediate marts` — 41 pass, 0 failures
- [ ] Business queries answered with actual numbers from the data
- [ ] `.mcp.json` has `dbt-bq` entry
