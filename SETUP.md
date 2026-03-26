# dbt MCP Demo — Setup Guide

A step-by-step guide to set up a dbt project with the official dbt MCP server and connect it to Claude Code.
Follow each phase in order. Every command is copy-pasteable.

---

## Shell / Terminal

All commands in this guide use **Git Bash** (installed with Git for Windows).

- Open it via: Start Menu > "Git Bash"
- Do NOT use CMD — forward slashes and Unix commands won't work
- PowerShell is only needed for installing tools (noted where relevant)

### Path formats — important on Windows

Git Bash and Windows use different path formats:

| Context | Format | Example |
|---|---|---|
| Git Bash commands | Unix style | `/c/Users/kriparam/Documents/dbt-mcp-demo` |
| JSON config files (MCP settings) | Windows style | `C:/Users/kriparam/Documents/dbt-mcp-demo` |
| Windows env vars | Windows style | `C:\Users\kriparam\Documents\dbt-mcp-demo` |

In JSON config files, use forward slashes (`C:/Users/...`) — Windows accepts them and you avoid escaping backslashes.

---

## Prerequisites

Before starting, verify these tools are installed:

```bash
python --version        # need 3.10+
uv --version            # need uv (Python package manager)
dbt --version           # need dbt-fusion or dbt-core
```

### Install uv (if missing)
```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### Install dbt-fusion (if missing)
```bash
# macOS / Linux
curl -fsSL https://dl.dbt.com/install.sh | sh

# Windows — download installer from:
# https://docs.getdbt.com/docs/dbt-versions/core-upgrade
```

---

## Phase 1 — dbt Project (DuckDB / inline prototype)

### 1.1 — Understand the data model

Jaffle Shop is a fictional coffee shop — dbt Labs' "hello world" project.

The data model has 3 layers:

```
SEEDS (raw CSVs loaded into DB)
  raw_customers, raw_orders, raw_items, raw_products, raw_stores, raw_supplies

STAGING (views — clean and rename raw data, no business logic)
  stg_customers, stg_orders, stg_order_items, stg_products, stg_locations, stg_supplies

MARTS (tables — joins, aggregations, business logic)
  customers, orders, order_items, products, locations, supplies
```

DAG (built automatically from `{{ ref() }}` calls in SQL):
```
raw_* --> stg_* --> mart models
```

No external database needed for the prototype — dbt-fusion's `--compute inline` mode
runs everything in-process (like DuckDB).

---

### 1.2 — Initialize the jaffle-shop project

```bash
# Navigate to your working directory first
cd ~/Documents/dbt-mcp-demo       # change this to your preferred path

# Initialize jaffle-shop sample project (skips interactive profile setup)
dbt init --project-name jaffle_shop --skip-profile-setup --sample jaffle-shop
```

This creates a `jaffle_shop/` folder with:

```
jaffle_shop/
├── dbt_project.yml          # project config — name, profile, materialization settings
├── packages.yml             # external dbt packages
├── seeds/                   # raw CSV data (loaded into DB by dbt seed)
│   ├── raw_customers.csv
│   ├── raw_orders.csv
│   ├── raw_items.csv
│   ├── raw_products.csv
│   ├── raw_stores.csv
│   └── raw_supplies.csv
├── models/
│   ├── staging/             # clean + rename raw data (materialized as views)
│   │   ├── __sources.yml    # declares where raw tables live
│   │   ├── stg_customers.sql + .yml
│   │   ├── stg_orders.sql + .yml
│   │   └── ...
│   └── marts/               # business logic joins + aggregations (materialized as tables)
│       ├── customers.sql + .yml
│       ├── orders.sql + .yml
│       └── ...
└── macros/
    └── cents_to_dollars.sql # reusable SQL macro
```

### 1.3 — Understand the generated files

**`dbt_project.yml`** — the root config file
- `profile: jaffle_shop` — points to a connection in `~/.dbt/profiles.yml`
- `+schema: raw` under seeds — seeds land in a `<target>_raw` schema
- `+materialized: view` for staging — no data stored, just SQL views
- `+materialized: table` for marts — data physically written to tables

**`models/staging/__sources.yml`** — source declarations
- Tells dbt where raw data lives (which schema + table names)
- Enables `{{ source('ecom', 'raw_orders') }}` references
- Powers data freshness checks and lineage tracking

**`models/staging/stg_orders.sql`** — a staging model
- `{{ ref('raw_orders') }}` — dbt tracks this as a dependency, builds the DAG
- `{{ cents_to_dollars('subtotal') }}` — calls a macro (avoids repeating logic)
- Only renames and casts — no business logic here

**`models/marts/orders.sql`** — a mart model
- References staging models via `{{ ref('stg_orders') }}`
- Joins, aggregates, derives columns — this is where business logic lives
- Output is a clean table for analysts to query

### DAG (dependency graph) — built automatically from ref() calls

```
raw_customers --> stg_customers --> customers
raw_orders    --> stg_orders    --> orders
raw_items     --> stg_order_items       |
raw_products  --> stg_products --> products
raw_stores    --> stg_locations --> locations
raw_supplies  --> stg_supplies --> supplies
```

---

### 1.4 — Run dbt build

First, create `~/.dbt/profiles.yml` (dbt looks here for DB connection info):

```bash
mkdir -p ~/.dbt
```

Create `~/.dbt/profiles.yml` with this content (replace the path with your own):

```yaml
jaffle_shop:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: "C:/Users/YOUR_USERNAME/Documents/dbt-mcp-demo/jaffle_shop/jaffle_shop.duckdb"
      threads: 4
```

The `path` is where DuckDB stores your data as a local file. Use forward slashes on Windows.

Now run the build:

```bash
cd jaffle_shop

# Run everything: seeds + models + tests in dependency order
dbt build
```

What this does in order:
1. `dbt seed` — loads CSVs from `seeds/` into raw tables in DuckDB
2. `dbt run` — executes all SQL models (staging views + mart tables)
3. `dbt test` — runs all schema tests (not_null, unique, relationships, expression_is_true)

Expected output:
```
Processed: 12 models | 27 tests | 6 seeds | 3 unit tests
Summary: 48 total | 48 success
```

To run steps individually:
```bash
dbt seed                          # load CSVs only
dbt run                           # run models only
dbt test                          # run tests only
dbt run --select staging          # run only staging models
dbt run --select orders           # run one specific model
```

### 1.5 — Inspect the output

```bash
# Preview data from a model (top 5 rows)
dbt show --select orders
dbt show --select customers

# List all models in the project
dbt ls

# Compile SQL without running (see the rendered SQL)
dbt compile --select stg_orders
```

---

### 1.6 — Query the DuckDB file directly

dbt-fusion has DuckDB **built in** — no separate install needed to run dbt.
But to get an interactive SQL shell to explore the data, install the DuckDB CLI:

```bash
# Windows (run in Git Bash or PowerShell)
winget install DuckDB.cli
```

After installing, open a **new** Git Bash window (PATH needs to refresh), then connect:

```bash
duckdb C:/Users/YOUR_USERNAME/Documents/dbt-mcp-demo/jaffle_shop/jaffle_shop.duckdb
```

If `duckdb` is not on PATH yet (winget PATH update can lag), use the full path:

```bash
"/c/Users/YOUR_USERNAME/AppData/Local/Microsoft/WinGet/Packages/DuckDB.cli_Microsoft.Winget.Source_8wekyb3d8bbwe/duckdb.exe" \
  "C:/Users/YOUR_USERNAME/Documents/dbt-mcp-demo/jaffle_shop/jaffle_shop.duckdb"
```

Once connected, try these queries:

```sql
-- see all tables
SHOW TABLES;

-- top customers by spend
SELECT customer_name, count_lifetime_orders, lifetime_spend, customer_type
FROM main.customers
ORDER BY lifetime_spend DESC
LIMIT 10;

-- look at raw data BEFORE transformation
SELECT * FROM main_raw.raw_orders LIMIT 5;

-- look at orders AFTER transformation
SELECT order_date, order_total, is_food_order, is_drink_order, customer_order_number
FROM main.orders
LIMIT 10;

-- exit
.quit
```

**Two schemas in one file:**

| Schema | What's in it | How it got there |
|---|---|---|
| `main_raw` | raw_customers, raw_orders, raw_items... | `dbt seed` loaded the CSVs here |
| `main` | stg_*, customers, orders, products... | `dbt run` built models here |

This is the `+schema: raw` setting in `dbt_project.yml` — seeds land in a separate
schema from models, keeping raw data isolated from transformed data.

**What dbt actually transformed (raw → clean):**

| Column | raw_orders (before) | orders (after) |
|---|---|---|
| order id | `id` | `order_id` |
| customer ref | `customer` | `customer_id` |
| store ref | `store_id` | `location_id` |
| amount | `subtotal = 700` (cents) | `subtotal = 7.00` (dollars) |
| timestamp | `ordered_at = 2016-09-01 15:01:00` | `order_date = 2016-09-01` |
| enriched cols | none | `count_food_items`, `is_food_order`, `customer_order_number`... |

The staging layer does the renaming/casting. The mart layer adds the enrichment.

**DuckDB file locking — important:**

DuckDB locks the **entire `.duckdb` file** when any process opens it — not just the
table being queried. This means:

- If the DuckDB CLI is open in one terminal, `dbt run` in another terminal will fail
- Close the CLI (`.quit`) before running any dbt commands
- This is by design — DuckDB is a single-user embedded database (like SQLite)

```
DuckDB CLI open  ──► holds write lock on entire jaffle_shop.duckdb
dbt run          ──► tries to open same file ──► ERROR: file in use
```

Fix: always `.quit` the DuckDB CLI before running dbt commands.

This limitation goes away with BigQuery — it's a server-based warehouse with no
file locking. Multiple processes can read/write simultaneously.

| Database | Locking model |
|---|---|
| DuckDB | Entire file locked per connection |
| SQLite | Entire file locked per connection |
| PostgreSQL | Row-level locks, thousands of concurrent connections |
| BigQuery | No locks — serverless, fully managed |

---

## Phase 2 — Install dbt Agent Skills

### What are dbt agent skills?

Skills are markdown files that tell Claude how to behave for specific dbt tasks.
They live in your project's `.claude/commands/` folder. Claude reads them automatically
when your message matches what the skill is for — no slash command needed.

They are NOT Python packages, not processes, not code.
Just markdown files with instructions. When you ask Claude something dbt-related,
it reads the relevant skill file and follows its guidance.

```
jaffle_shop/
└── .claude/
    └── commands/
        ├── running-dbt-commands.md
        ├── using-dbt-for-analytics-engineering.md
        ├── troubleshooting-dbt-job-errors.md
        └── ...
```

The skills come from the official dbt Labs repo:
`https://github.com/dbt-labs/dbt-agent-skills`

### The 8 skills and what each one does

| Skill file | Activates when you... |
|---|---|
| `running-dbt-commands.md` | Ask to run dbt commands — picks the right executable, flags, selector syntax |
| `using-dbt-for-analytics-engineering.md` | Build or modify models, write SQL transformations, explore data |
| `troubleshooting-dbt-job-errors.md` | Ask why a model or test is failing — systematic diagnosis, not quick fixes |
| `configuring-dbt-mcp-server.md` | Set up the dbt MCP server in Claude Code, Cursor, or VS Code |
| `adding-dbt-unit-test.md` | Add unit tests to models — when to use them, how to structure them |
| `fetching-dbt-docs.md` | Look up dbt documentation — fetches in markdown format efficiently |
| `answering-natural-language-questions-with-dbt.md` | Ask business questions about data ("what were sales last month?") |
| `building-dbt-semantic-layer.md` | Create semantic models, metrics, dimensions with MetricFlow |

### How to install

```bash
# Navigate to the jaffle_shop project directory
cd /c/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop

# Create the .claude/commands directory
mkdir -p .claude/commands

# Download all 8 skills directly from the dbt-labs GitHub repo
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
  echo "Downloaded: ${skill}.md"
done
```

Each `curl` command fetches one raw markdown file from the dbt-labs GitHub repo
and saves it into `.claude/commands/`. That's the entire install — 8 file downloads.

### Verify the install

```bash
ls -la .claude/commands/
```

You should see 8 `.md` files ranging from 3KB to 17KB each.

### How Claude uses them

Once the files are in `.claude/commands/`, Claude Code reads them as context
when you open a conversation in that project directory. When you ask something
like "why is my model failing?", Claude matches your question to the
`troubleshooting-dbt-job-errors.md` skill and follows its diagnostic workflow.

You don't type a slash command. It's automatic based on what you ask.

---

## Phase 3 — MCP Server (connect to Claude Code)

### Why the config lives at the workspace level

The MCP server config goes in `dbt-mcp-demo/.claude/settings.json` — NOT inside
`jaffle_shop/` and NOT in the global `~/.claude/settings.json`.

Reasons:
- The dbt MCP server serves the whole workspace, not just the dbt project
- When Airflow or other tools are added later, their MCP servers go in the same file
- Global `~/.claude/settings.json` would apply to every project you open — too broad

```
dbt-mcp-demo/
└── .claude/
    └── settings.json    ← MCP server config lives here (workspace level)
jaffle_shop/
└── .claude/
    └── commands/        ← skills live here (dbt project level)
```

---

### 3.1 — Understand the config format

Claude Code launches the MCP server as a child process using the config in
`dbt-mcp-demo/.claude/settings.json`. The server communicates via stdio
(stdin/stdout pipes) — no ports, no HTTP for local setup.

When Claude Code starts, it reads the config, spawns the `uvx dbt-mcp` process,
and the tools become available in your conversation automatically.

```
Claude Code ──(stdin/stdout pipe)──► uvx dbt-mcp process ──► dbt commands ──► DuckDB / BigQuery
```

---

### 3.2 — Test the dbt MCP server manually

Before wiring it into Claude Code, verify it starts without crashing on its own.
If it errors here, the problem is in the config (wrong path, missing package) — not Claude Code.

```bash
DBT_PROJECT_DIR="C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop" \
DBT_PATH="C:/Users/kriparam/.local/bin/dbt.exe" \
DISABLE_SEMANTIC_LAYER=true \
DISABLE_DISCOVERY_API=true \
uvx dbt-mcp
```

The server is a Python process that starts, reads the env vars, then sits idle on stdin
waiting for JSON messages from Claude Code. It does not open a port or serve HTTP.

Press Ctrl+C to stop it.

Expected output:
```
WARNING [dbt_mcp.config.settings] Platform features have been automatically disabled due to missing DBT_HOST.
INFO [dbt_mcp.mcp.server] Registering product docs tools
INFO [dbt_mcp.mcp.server] Registering MCP server tools
INFO [dbt_mcp.mcp.server] Registering dbt cli tools
INFO [dbt_mcp.mcp.server] Registering dbt codegen tools
INFO [dbt_mcp.mcp.server] Registering LSP tools
INFO [dbt_mcp.mcp.server] Starting MCP server
INFO [dbt_mcp.lsp.providers.local_lsp_connection_provider] Using LSP binary in C:/Users/.../dbt-lsp.exe
INFO [dbt_mcp.lsp.lsp_connection] LSP server started with PID: XXXXX
INFO [dbt_mcp.lsp.lsp_connection] LSP server initialized successfully
```
Then it stops scrolling — this is correct. The server is idle on stdin, waiting for JSON.

What each section means:
- `WARNING ... missing DBT_HOST` — expected, Cloud tools auto-disabled (no dbt Cloud)
- `Registering * tools` — server loading each tool group into memory
- `Starting MCP server` — now listening on stdin for messages from Claude Code
- `LSP binary ... dbt-lsp.exe` — bonus: found the dbt Language Server from VS Code dbt
  extension, enables go-to-definition and code intelligence on dbt models

Press Ctrl+C to stop. No crash = server started cleanly.

---

### 3.3 — Add MCP server to Claude Code

Use the `claude mcp add` command to register the dbt MCP server at project scope.
This creates `.mcp.json` in the workspace root (`dbt-mcp-demo/.mcp.json`).

#### 3.3.1 — Find your dbt path

```bash
which dbt          # Git Bash → e.g. /c/Users/kriparam/.local/bin/dbt
where dbt          # Windows CMD → e.g. C:\Users\kriparam\.local\bin\dbt.exe
```

#### 3.3.2 — Register the MCP server

Run this from the `dbt-mcp-demo/` workspace root:

```bash
claude mcp add dbt -s project \
  -e DBT_PROJECT_DIR="C:/Users/kriparam/Documents/dbt-mcp-demo/jaffle_shop" \
  -e DBT_PATH="C:/Users/kriparam/.local/bin/dbt.exe" \
  -- uvx dbt-mcp
```

What each flag does:
- `-s project` — project scope, writes to `.mcp.json` in current directory (not global)
- `-e KEY=VALUE` — sets environment variables the MCP server process will see
- `-- uvx dbt-mcp` — the command Claude Code runs to start the server

#### 3.3.3 — Disable Cloud-only tools

The dbt MCP server has 4 tool groups. Two require dbt Cloud (Semantic Layer,
Discovery API) and will error with DuckDB. Edit `.mcp.json` to disable them:

```bash
# .mcp.json is at dbt-mcp-demo/.mcp.json — edit it to add the two disable flags
```

The final `.mcp.json` should look like:

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

| Tool group | Env var to disable | Works with DuckDB? |
|---|---|---|
| dbt CLI (run, build, test, compile, show) | — | Yes |
| SQL (text_to_sql, execute_sql) | `DISABLE_SQL=false` to enable | Yes |
| Semantic Layer (metrics, dimensions) | `DISABLE_SEMANTIC_LAYER=true` | No — needs dbt Cloud |
| Discovery API (models, lineage metadata) | `DISABLE_DISCOVERY_API=true` | No — needs dbt Cloud |

When Airflow is added later, its MCP server goes in the same `.mcp.json`:
```json
{
  "mcpServers": {
    "dbt": { ... },
    "airflow": {
      "command": "uvx",
      "args": ["airflow-mcp"],
      "env": {
        "AIRFLOW_HOST": "http://localhost:8080"
      }
    }
  }
}
```

---

### 3.4 — Verify connection

After restarting Claude Code, run:
```
/mcp
```

You should see the dbt server listed as connected with tools like:
- `dbt_run` — run models
- `dbt_test` — run tests
- `dbt_build` — run everything
- `dbt_compile` — compile SQL
- `dbt_list` — list models
- `dbt_show` — preview data

---

## Phase 4 — Claude Code Custom Skills

### 4.1 — What is a Claude Code skill

A skill is a markdown file in `~/.claude/commands/`. When you type `/skill-name` in Claude Code,
the markdown content becomes Claude's instruction for that task.

Skills differ from MCP tools:
- MCP tool = a function Claude can call (e.g. run dbt, query metadata)
- Skill = a prompt template that tells Claude HOW to behave for a workflow

Skills typically USE MCP tools under the hood. Example: `/dbt-run` skill tells Claude
"ask for model selection, call dbt_run, then summarize the output clearly."

---

### 4.2 — Create /dbt-run skill

Create `~/.claude/commands/dbt-run.md`:

```markdown
Run dbt models for the jaffle_shop project.

The user may specify:
- A model name or tag to select
- Whether to run upstream dependencies (+model) or downstream (model+)
- If no selection given, run all models

Use the dbt_run MCP tool. After running, summarize:
- How many models ran successfully
- Any failures with the error message
- How long it took
```

### 4.3 — Create /dbt-test skill

Create `~/.claude/commands/dbt-test.md`:

```markdown
Run dbt tests for the jaffle_shop project.

Use the dbt_test MCP tool. After running:
- Report pass/fail counts
- For any failures, explain what the test was checking and why it likely failed
- Suggest fixes for common issues (null values, duplicate keys, broken relationships)
```

---

### 4.4 — Create CLAUDE.md (project conventions)

`CLAUDE.md` lives at the **workspace root** (`dbt-mcp-demo/CLAUDE.md`). Claude Code reads it
automatically as project-level context in every conversation. It replaces the need to repeat
project conventions in every prompt.

Create `dbt-mcp-demo/CLAUDE.md` with:

```markdown
# dbt Project Conventions — jaffle_shop

## Architecture — 4-layer data model
Seeds → Staging (views) → Intermediate (views) → Marts/Gold (tables)

## Naming conventions
- Staging: stg_<entity>.sql
- Intermediate: int_<topic>_<verb>.sql
- Dimension: dim_<entity>.sql
- Fact: fct_<event>.sql
- YAML: _<layer>_jaffle_shop.yml per folder

## Testing philosophy — lineage-aware
Do not re-test columns already tested upstream. Check what's covered before adding tests.
Rules:
1. Primary keys: always unique + not_null
2. Foreign keys: not_null at the layer where the join first happens; skip downstream
3. Pass-through columns: skip if already tested in staging
4. Derived/computed columns: not_null on key metrics (order_total, total_gross_margin)
5. Categorical columns: accepted_values on enumerations (customer_segment)

Document the lineage decision in the column description:
  description: "Foreign key to stg_customers. Not re-tested — already covered upstream."

## dbt-fusion notes
- accepted_values requires the arguments: wrapper
- DuckDB locks the file — close CLI before running dbt
- Amounts in raw seeds are in cents; staging converts to dollars via cents_to_dollars()

## MCP tools
Always use MCP tools (dbt_build, dbt_run, dbt_test, dbt_show, dbt_list) — not Bash.
```

---

### 4.5 — Lineage-aware test audit

This is the "aha moment" of the demo: Claude traces column lineage across all 4 layers,
identifies genuine test gaps vs columns already covered upstream, and adds tests only where
they're actually missing.

#### How to run it

With the dbt MCP server connected, use this prompt in Claude Code:

```
Audit the test coverage across the jaffle_shop project.
For each model, use lineage to check what's already tested in upstream models.
Don't re-test pass-through columns that are already covered.
Show me which tests exist upstream so I can see you've checked.
Then implement the missing tests where genuine gaps exist.
```

#### What Claude does (the reasoning steps)

**Step 1 — Read all staging YAML files** to build an upstream test map:

| Staging model | Tests already in place |
|---|---|
| `stg_customers` | `customer_id` (unique, not_null) |
| `stg_orders` | `order_id` (unique, not_null); model-level: `order_total - tax_paid = subtotal` |
| `stg_order_items` | `order_item_id` (unique, not_null); `order_id` (not_null + relationship) |
| `stg_products` | `product_id` (unique, not_null) |
| `stg_locations` | `location_id` (unique, not_null); unit test for date truncation |
| `stg_supplies` | `supply_uuid` (unique, not_null) |

**Step 2 — Trace every intermediate/mart column** against the upstream map.

Key decisions:
- `customer_id`, `location_id`, `product_id` FKs — stg PKs cover these; not re-tested
- `subtotal`, `tax_paid` — stg_orders model-level expression covers these; not re-tested
- `order_date` — **stg_orders does NOT test this column** → genuine gap → add `not_null`
- `fct_orders.order_date` — covered by int layer fix; skip in gold
- `is_food_order`, `is_drink_order` — derived booleans; no test needed

**Step 3 — Add tests only for genuine gaps:**

| Column | Model | Reason for adding |
|---|---|---|
| `order_date` | `int_orders_enriched` | Not tested anywhere upstream |
| `order_total` | `int_orders_enriched` | Derived; not tested upstream |
| `product_price` | `int_order_items_enriched` | Not tested upstream |
| `gross_margin` | `int_order_items_enriched` | Derived (price - cost) |
| `avg_order_value` | `dim_customers` | Derived `AVG()` |
| `first_order_date` | `dim_customers` | Derived `MIN()` |
| `last_order_date` | `dim_customers` | Derived `MAX()` |
| `locations_visited` | `dim_customers` | Derived `COUNT(DISTINCT)` |
| `order_total` | `fct_orders` | Derived; not re-tested at gold layer explicitly |
| `count_items` | `fct_orders` | Derived `COUNT()` with `COALESCE` |
| `count_food_items` | `fct_orders` | Derived `SUM(CASE...)` with `COALESCE` |
| `count_drink_items` | `fct_orders` | Same |
| `total_gross_margin` | `fct_orders` | Derived aggregate |
| `customer_order_number` | `fct_orders` | Derived `ROW_NUMBER()` |

**Step 4 — Run `dbt test --select intermediate marts`**

Expected result: all tests pass (41 total including staging + intermediate + marts).

#### Lineage-aware description pattern

Every pass-through column that skips a test gets this comment in YAML:
```yaml
- name: customer_id
  description: "Foreign key to stg_customers. Not re-tested — already covered upstream."
```

Every derived column that gets a test explains why:
```yaml
- name: order_date
  description: "stg_orders does not test this column — genuine gap."
  data_tests:
    - not_null
```

---

## Phase 5 — BigQuery

### 5.1 — Authentication options

**Option A: gcloud CLI (recommended)**
```bash
# Install from: https://cloud.google.com/sdk/docs/install
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

**Option B: Service account key (no gcloud needed)**
1. Go to GCP Console > IAM > Service Accounts
2. Create a key (JSON format), download it
3. Set env var: `GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json`

### 5.2 — Install dbt-bigquery adapter

```bash
pip install dbt-bigquery
# OR with uv:
uv pip install dbt-bigquery
```

### 5.3 — Update profiles.yml

Edit `~/.dbt/profiles.yml`:

```yaml
jaffle_shop:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth                        # or 'service-account' for key file
      project: your-gcp-project-id
      dataset: jaffle_shop_dev
      threads: 4
      timeout_seconds: 300
      # for service account:
      # method: service-account
      # keyfile: /path/to/keyfile.json
```

### 5.4 — Run against BigQuery

```bash
cd jaffle_shop

# No --compute inline flag needed — remote is the default
dbt build

# Or with explicit target
dbt build --target dev
```

Everything else (models, seeds, tests, MCP server) stays the same.
Only the connection in `profiles.yml` changes.

---

## Quick Reference

| Command | What it does |
|---|---|
| `dbt build` | Run everything (seeds + models + tests) |
| `dbt run --select stg_*` | Run only staging models |
| `dbt test --select orders` | Test one model |
| `dbt show --select customers` | Preview 5 rows from a model |
| `dbt ls` | List all models |
| `dbt compile --select stg_orders` | See rendered SQL without running |
| `uvx dbt-mcp` | Start the MCP server |

## Troubleshooting

**`dbt: command not found`**
- Check `which dbt` / `where dbt`
- May need to add `~/.local/bin` to your PATH

**`profile not found`**
- dbt looks for `~/.dbt/profiles.yml` by default
- Run `dbt debug` to see what profile it's looking for and where

**MCP tools not showing in Claude Code**
- Restart Claude Code after editing settings
- Check paths use forward slashes even on Windows
- Run `uvx dbt-mcp` manually first to confirm it starts without errors
