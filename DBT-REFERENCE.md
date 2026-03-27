# dbt Reference Tables

---

## dbt MCP Tools

| Tool | What it does | Example use |
|---|---|---|
| `dbt_build` | Seeds + models + tests in one command | Build everything from scratch |
| `dbt_run` | Run models only | Re-run after a SQL fix |
| `dbt_test` | Run tests only | Verify data quality after load |
| `dbt_seed` | Load CSVs into the warehouse | Reload raw data |
| `dbt_compile` | Render Jinja/SQL without executing | Debug a model's SQL before running |
| `dbt_show` | Preview rows from a model | Check what `dim_customers` looks like |
| `dbt_list` | List all nodes in the project | See all models, seeds, tests |
| `dbt_deps` | Install packages from packages.yml | First-time setup or after adding a package |

---

## dbt Agent Skills

| Skill | When to use it |
|---|---|
| `/running-dbt-commands` | When you need the right CLI flags, selectors, or command structure |
| `/using-dbt-for-analytics-engineering` | Core skill — building models, writing SQL, creating tests |
| `/troubleshooting-dbt-job-errors` | When a build fails and you need help diagnosing logs |
| `/configuring-dbt-mcp-server` | Setting up or fixing `.mcp.json` and MCP connectivity |
| `/adding-dbt-unit-test` | Writing unit tests with mocked inputs and expected outputs |
| `/fetching-dbt-docs` | Looking up dbt features or syntax mid-task |
| `/answering-natural-language-questions-with-dbt` | Translating a business question into a SQL query |
| `/building-dbt-semantic-layer` | Creating MetricFlow metrics, semantic models, dimensions |

---

## MCP Tools vs Skills

| | MCP Tools | Skills |
|---|---|---|
| What they are | Executable functions | Markdown instruction files |
| What they do | Actually run dbt commands | Tell Claude how to approach a task |
| Analogy | The hands | The brain |
| Lives in | `.mcp.json` → dbt-mcp server | `.claude/commands/*.md` |
| Invoked by | Claude automatically | You type `/skill-name` |
| Activated automatically | Yes | No — must be explicitly called |

---

## Project Comparison

| | `jaffle_shop` | `jaffle_shop_bq` | `jaffle_shop_cloud` |
|---|---|---|---|
| **Runtime** | dbt-fusion local | dbt-fusion local | dbt Cloud (managed) |
| **Warehouse** | DuckDB (local file) | BigQuery | BigQuery |
| **Where code runs** | Your machine | Your machine | dbt Cloud servers |
| **Code source** | Local files | Local files | GitHub repo |
| **Auth** | None needed | JSON key file | Key uploaded to Cloud UI |
| **profiles.yml** | Required | Required | Not used in Cloud runs |
| **Seed type inference** | Auto (dbt-fusion) | Auto (dbt-fusion) | Manual `+column_types` required |
| **File locking** | Yes — close DuckDB CLI first | No | No |
| **Execute from** | Claude Code via MCP | Claude Code via MCP | dbt Cloud UI → jobs |
| **Scheduling** | Manual only | Manual only | Cron jobs in UI |
| **CI on PR** | No | No | Yes |
| **Hosted docs** | No | No | Yes |
| **Team access** | No | No | Yes |
| **Dataset (models)** | `main` schema | `jaffle_shop_fusion` | `jaffle_shop_cloud` / `_staging` / `_prod` |
| **Dataset (seeds)** | `main_raw` schema | `jaffle_shop_fusion_raw` | `jaffle_shop_cloud_staging_raw` |
| **MCP server name** | `dbt` | `dbt-bq` | N/A (runs in Cloud) |
| **Best for** | Fast local dev + demo | BQ dev without leaving Claude | Production + team workflows |

---

## dbt-fusion vs dbt-core

| | dbt-core | dbt-fusion |
|---|---|---|
| **Language** | Python | Rust |
| **SQL understanding** | Treats SQL as strings | Full SQL compiler |
| **Static analysis** | None | Errors caught before execution |
| **Performance** | Baseline | ~30x faster parsing, ~2x faster compilation |
| **Runtime needed** | Python + pip | Single binary, no Python needed |
| **Seed type inference** | Loads everything as STRING | Auto-detects column types from CSV |
| **Python models** | Supported | Hard blocked |
| **`+static_analysis` config** | Not available | Supported (`strict` mode) |
| **Inline editor errors** | Not available | VS Code extension flags errors as you type |
| **Live CTE previews** | Not available | See compiled SQL without running |
| **Column-level lineage** | Not available | Traced across entire DAG at compile time |
| **Licensing** | Apache 2.0 (open source) | Mixed — some features proprietary |
| **Used by dbt Cloud** | Yes (today) | Private preview — coming soon |

---

## What can be done from Claude CLI vs Manual

| Action | Claude Terminal | Manual (Browser/UI) |
|---|---|---|
| **dbt — models, tests, seeds** | | |
| Build everything (`dbt build`) | ✅ MCP | |
| Run specific models | ✅ MCP | |
| Run tests | ✅ MCP | |
| Load seeds | ✅ MCP | |
| Preview data (`dbt show`) | ✅ MCP | |
| List all nodes | ✅ MCP | |
| Compile SQL without running | ✅ MCP | |
| Install packages (`dbt deps`) | ✅ MCP | |
| Debug connection | ✅ Terminal | |
| **Files and code** | | |
| Write / edit models | ✅ Claude | |
| Write YAML tests | ✅ Claude | |
| Update dbt_project.yml | ✅ Claude | |
| Update profiles.yml | ✅ Claude | |
| Update .mcp.json | ✅ Claude | |
| **Git** | | |
| Commit changes | ✅ Terminal | |
| Push to GitHub | ✅ Terminal | |
| Merge PR | | ✅ GitHub UI |
| Set branch protection rules | | ✅ GitHub UI |
| **dbt Cloud setup** | | |
| Create account | | ✅ cloud.getdbt.com |
| Create project | | ✅ dbt Cloud UI |
| Configure BigQuery connection | | ✅ dbt Cloud UI |
| Upload service account key | | ✅ dbt Cloud UI |
| Connect GitHub repo | | ✅ dbt Cloud UI |
| Create environments (Dev/STG/PROD/CI) | | ✅ dbt Cloud UI |
| Create jobs | | ✅ dbt Cloud UI |
| Trigger job runs | | ✅ dbt Cloud UI |
| View job logs | | ✅ dbt Cloud UI |
| View hosted docs | | ✅ dbt Cloud UI |
| Set up CI check | | ✅ dbt Cloud UI |
| **GCP / BigQuery setup** | | |
| Create GCP project | | ✅ GCP Console |
| Enable BigQuery API | | ✅ GCP Console |
| Create service account | | ✅ GCP Console IAM |
| Assign IAM roles | | ✅ GCP Console IAM |
| Download JSON key | | ✅ GCP Console |
| Create datasets | ✅ dbt creates automatically | |
| Query data in console | ✅ via `dbt show` | ✅ BigQuery Console |

---

## CLI vs dbt Cloud — when do you need it

| Need | CLI (dbt-fusion) | dbt Cloud |
|---|---|---|
| Build and test models | ✅ Better (faster, static analysis) | ✅ Works |
| Preview data | ✅ `dbt show` | ✅ Cloud IDE |
| One developer | ✅ Perfect | Overkill |
| Scheduled production runs | ❌ Need a server | ✅ Built in |
| Team of engineers | ❌ No coordination layer | ✅ Environments, access control |
| CI on PRs | ❌ Need to set up yourself | ✅ Built in |
| Stakeholder-facing docs | ❌ Local only | ✅ Hosted, always fresh |
| Alerting on failures | ❌ | ✅ Slack, email, PagerDuty |
| Audit trail | ❌ | ✅ Who ran what, when |
| SSO / enterprise security | ❌ | ✅ Team/Enterprise plans |
| Cost | Free | $100–$500+/month per user |
