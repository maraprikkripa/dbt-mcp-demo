# dbt MCP Demo — Full Setup Prompt (Phases 1–4)

Use this prompt at the start of a new Claude Code conversation in the `dbt-mcp-demo/` directory
to complete the full setup autonomously.

---

## Prompt

I want to set up a dbt project connected to Claude Code via the dbt MCP server, using the
jaffle_shop sample project on DuckDB. Complete all four phases below in order.

---

### Phase 1 — Initialize the dbt project

1. Run `dbt init --project-name jaffle_shop --skip-profile-setup --sample jaffle-shop` inside
   `dbt-mcp-demo/` to scaffold the project.

2. Create `~/.dbt/profiles.yml` with a DuckDB connection:

```yaml
jaffle_shop:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: "C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop/jaffle_shop.duckdb"
      threads: 4
```

3. Run `dbt build` from inside `jaffle_shop/` to load seeds, run all models, and run all tests.
   Expected: 6 seeds + 12 models + tests all pass.

4. Verify with `dbt show --select customers` and `dbt show --select orders` to confirm data
   landed in DuckDB.

---

### Phase 2 — Install dbt agent skills

From inside `jaffle_shop/`, download all 8 official dbt agent skills from the
`dbt-labs/dbt-agent-skills` GitHub repo into `.claude/commands/`:

```bash
mkdir -p .claude/commands

SKILLS=(
  "running-dbt-commands"
  "using-dbt-for-analytics-engineering"
  "troubleshooting-dbt-job-errors"
  "configuring-dbt-mcp-server"
  "adding-dbt-unit-test"
  "fetching-dbt-docs"
  "answering-natural-language-questions-with-dbt"
  "building-dbt-semantic-layer"
)

for skill in "${SKILLS[@]}"; do
  curl -s "https://raw.githubusercontent.com/dbt-labs/dbt-agent-skills/main/skills/dbt/skills/${skill}/SKILL.md" \
    -o ".claude/commands/${skill}.md"
done
```

Verify with `ls -la .claude/commands/` — should show 8 `.md` files.

---

### Phase 3 — Configure the dbt MCP server

1. From `dbt-mcp-demo/` (the workspace root), register the MCP server at project scope:

```bash
claude mcp add dbt -s project \
  -e DBT_PROJECT_DIR="C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop" \
  -e DBT_PATH="C:/Users/kriparam/.local/bin/dbt.exe" \
  -- uvx dbt-mcp
```

2. Edit the generated `.mcp.json` to add the two disable flags for Cloud-only tools:

```json
{
  "mcpServers": {
    "dbt": {
      "type": "stdio",
      "command": "uvx",
      "args": ["dbt-mcp"],
      "env": {
        "DBT_PROJECT_DIR": "C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop",
        "DBT_PATH": "C:/Users/kriparam/.local/bin/dbt.exe",
        "DISABLE_SEMANTIC_LAYER": "true",
        "DISABLE_DISCOVERY_API": "true"
      }
    }
  }
}
```

3. Restart Claude Code, then run `/mcp` to confirm the dbt server is listed as connected.

---

### Phase 4 — Build a four-layer DuckDB architecture

The existing project has raw seeds, staging views, and mart tables. Extend it with an
intermediate layer and two new gold models.

#### What exists

**Seeds:** `raw_customers` (ID, NAME), `raw_orders` (ID, CUSTOMER, ORDERED_AT, STORE_ID,
SUBTOTAL, TAX_PAID, ORDER_TOTAL), `raw_items` (id, order_id, sku), `raw_products` (sku, name,
type, price, description), `raw_stores` (id, name, opened_at, tax_rate), `raw_supplies` (id,
name, cost, perishable, sku)

**Staging views** (already rename/cast raw columns):
- `stg_customers`: `customer_id`, `customer_name`
- `stg_orders`: `order_id`, `location_id`, `customer_id`, `subtotal`, `tax_paid`, `order_total` (dollars), `order_date`
- `stg_order_items`: `order_item_id`, `order_id`, `product_id`
- `stg_products`: `product_id`, `product_name`, `product_type`, `product_price`, `is_food_item`, `is_drink_item`
- `stg_locations`: `location_id`, `location_name`, `tax_rate`, `opened_date`
- `stg_supplies`: `supply_uuid`, `supply_id`, `product_id`, `supply_name`, `supply_cost`, `is_perishable_supply`

#### 4.1 — Add intermediate layer

Create `models/intermediate/int_orders_enriched.sql`:
- Join `stg_orders` + `stg_customers` + `stg_locations`
- Output: `order_id`, `order_date`, `customer_id`, `customer_name`, `location_id`, `location_name`, `tax_rate`, `subtotal`, `tax_paid`, `order_total`

Create `models/intermediate/int_order_items_enriched.sql`:
- Join `stg_order_items` + `stg_products` + supply costs aggregated from `stg_supplies` (sum `supply_cost` per `product_id`)
- Output: `order_item_id`, `order_id`, `product_id`, `product_name`, `product_type`, `product_price`, `is_food_item`, `is_drink_item`, `supply_cost`, `gross_margin` (product_price - supply_cost)

Create `models/intermediate/_int_jaffle_shop.yml` using the **lineage-aware test pattern**:
- Test `unique` + `not_null` on primary keys (`order_item_id`, `order_id`)
- Test `not_null` on derived/computed columns (`order_total`, `product_price`, `gross_margin`)
- For pass-through columns already tested in staging, skip the test and note it in the description:
  `"Foreign key to stg_customers. Not re-tested — already covered upstream."`

#### 4.2 — Add gold layer models

Create `models/marts/dim_customers.sql`:
- Source: `int_orders_enriched`
- Aggregate per customer: `total_orders`, `total_spend`, `avg_order_value`, `first_order_date`, `last_order_date`, `locations_visited`
- Derive `customer_segment`: Gold (total_spend >= $100), Silver (>= $50), Bronze (< $50)

Create `models/marts/fct_orders.sql`:
- Source: `int_orders_enriched` joined to item summary from `int_order_items_enriched`
- Item summary aggregated per order: `count_items`, `count_food_items`, `count_drink_items`, `total_supply_cost`, `total_gross_margin`
- Derive: `is_food_order`, `is_drink_order`, `customer_order_number` (row_number partitioned by `customer_id`, ordered by `order_date`)

Create `models/marts/_gold_jaffle_shop.yml` using the **lineage-aware test pattern**:
- Test `unique` + `not_null` on primary keys (`customer_id`, `order_id`)
- Test `not_null` on key metrics (`total_spend`, `total_orders`, `order_total`, `total_gross_margin`)
- Test `accepted_values` on `customer_segment`
- For pass-through columns, skip tests and note: `"Not re-tested — already covered upstream."`

> **dbt-fusion note:** all test arguments must use the `arguments:` wrapper:
> ```yaml
> - accepted_values:
>     arguments:
>       values: ['Gold', 'Silver', 'Bronze']
> ```

#### 4.3 — Update dbt_project.yml

Add `intermediate: +materialized: view` to the models config block:

```yaml
models:
  jaffle_shop:
    staging:
      +materialized: view
    intermediate:
      +materialized: view
    marts:
      +materialized: table
```

#### 4.4 — Create CLAUDE.md

Create `CLAUDE.md` at the **workspace root** (`dbt-mcp-demo/CLAUDE.md`) — not inside `jaffle_shop/`.
Claude Code reads this automatically as project-level context in every conversation.

Include these sections:
- **Architecture** — the 4-layer model (Seeds → Staging → Intermediate → Marts)
- **Naming conventions** — `stg_`, `int_`, `dim_`, `fct_` prefixes, YAML file naming
- **Testing philosophy** — lineage-aware rules (PK tests, FK tests once, skip pass-throughs, not_null on computed columns, accepted_values on enums)
- **dbt-fusion notes** — `arguments:` wrapper for tests, DuckDB file locking, cents-to-dollars
- **MCP tools** — use `dbt_build`, `dbt_run`, `dbt_test`, `dbt_show`, `dbt_list` instead of Bash

#### 4.5 — Build and verify

1. Run `mcp__dbt__build` — no selector, build everything
2. Run `mcp__dbt__list` with `resource_type: ["model", "seed"]` — confirm all 22 nodes appear
   across raw, staging, intermediate, and mart layers
3. Run `mcp__dbt__show` to verify gold layer data:
   - `dim_customers` grouped by `customer_segment` — check Gold/Silver/Bronze counts
   - `fct_orders` totals — check order count, total revenue, gross margin
   - Top 10 customers by `total_spend`
   - Revenue by `location_name`

#### 4.6 — Lineage-aware test audit

After the build passes, perform a full lineage-aware test audit across all 4 layers.

**Step 1 — Read all 6 staging YAML files** and build this upstream coverage map:

| Staging model | Tested columns |
|---|---|
| `stg_customers` | `customer_id` (unique, not_null) |
| `stg_orders` | `order_id` (unique, not_null); model-level expression: `order_total - tax_paid = subtotal` |
| `stg_order_items` | `order_item_id` (unique, not_null); `order_id` (not_null + relationship) |
| `stg_products` | `product_id` (unique, not_null) |
| `stg_locations` | `location_id` (unique, not_null); unit test for date truncation |
| `stg_supplies` | `supply_uuid` (unique, not_null) |

**Step 2 — Trace every column in intermediate + mart models** against the upstream map.

Lineage decisions to apply:
- FK columns pointing to a tested PK (e.g. `customer_id → stg_customers.customer_id`) → skip, mark description with "Not re-tested — already covered upstream"
- `subtotal`, `tax_paid` → covered by stg_orders model-level expression → skip
- `order_date` in `stg_orders` → **NOT tested anywhere** → genuine gap → add `not_null`
- `fct_orders.order_date` → covered by the int layer fix → skip at gold layer
- Derived booleans (`is_food_order`, `is_drink_order`) → no test needed
- COALESCE-protected columns (`supply_cost`, `total_supply_cost`) → always not_null by construction → no test needed

**Step 3 — Add tests for all genuine gaps:**

`models/intermediate/_int_jaffle_shop.yml`:
- `int_orders_enriched`: `order_id` (unique, not_null), `order_date` (not_null), `order_total` (not_null)
- `int_order_items_enriched`: `order_item_id` (unique, not_null), `product_price` (not_null), `gross_margin` (not_null)

`models/marts/_gold_jaffle_shop.yml`:
- `dim_customers`: `customer_id` (unique, not_null), `customer_name`/`total_orders`/`total_spend`/`avg_order_value`/`first_order_date`/`last_order_date`/`locations_visited` (all not_null), `customer_segment` (accepted_values: Gold, Silver, Bronze)
- `fct_orders`: `order_id` (unique, not_null), `customer_id` (not_null), `order_total`/`count_items`/`count_food_items`/`count_drink_items`/`total_gross_margin`/`customer_order_number` (all not_null)

**Step 4 — Run `dbt test --select intermediate marts`**

Expected: all 41 tests pass (39 schema tests + 2 unit tests).

---

## Success criteria

- `dbt build` passes with no errors (two dbt-fusion warnings about `--warn-error-options` and
  `--use-colors` are harmless and expected — ignore them)
- `/mcp` shows dbt server connected with tools listed
- `dbt list` shows 22 nodes across all four layers
- `dim_customers` returns rows with `customer_segment` in `['Gold', 'Silver', 'Bronze']`
- `fct_orders` has non-null `total_gross_margin` values
- `.claude/commands/` contains 8 skill `.md` files
- `CLAUDE.md` exists at the workspace root with conventions and testing philosophy
- All YAML files use lineage-aware descriptions (pass-through columns note upstream coverage)
- `dbt test --select intermediate marts` passes 41 tests with no failures
