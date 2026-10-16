# Git Access — dbt-mcp-demo

**Repo:** https://github.com/maraprikkripa/dbt-mcp-demo
**GitHub account:** maraprikkripa
**Local git user:** kriparam (different account — needs PAT to push)

---

## Why a PAT is needed

The local machine is authenticated as `kriparam` but the repo belongs to `maraprikkripa`.
GitHub rejects pushes from a different account without explicit authentication.
A Personal Access Token (PAT) from `maraprikkripa` is used to authenticate the push.

---

## One-time setup — generate a PAT

1. Log into GitHub as **maraprikkripa**
2. Profile picture (top right) → **Settings** → scroll to bottom → **Developer settings**
3. Personal access tokens → Tokens (classic) → **Generate new token (classic)**
4. Scope: check **`repo`** only
5. Set expiration (30 days recommended for demos)
6. Copy the token — it starts with `ghp_`

---

## Push commands

### Option A — Single push with token inline (token not saved)

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo

git push https://maraprikkripa:<YOUR_PAT>@github.com/maraprikkripa/dbt-mcp-demo.git main
```

### Option B — Set remote URL temporarily, push, then reset

```bash
# Set token in remote URL
git remote set-url origin https://maraprikkripa:<YOUR_PAT>@github.com/maraprikkripa/dbt-mcp-demo.git

# Push
git push -u origin main

# Reset remote URL to remove token (do this immediately after push)
git remote set-url origin https://github.com/maraprikkripa/dbt-mcp-demo.git
```

> Always reset the URL after pushing — never leave a token in the remote URL.

---

## Day-to-day workflow

```bash
cd /c/Users/kriparam/Documents/dbt-mcp-demo

# Stage changes
git add <files>

# Commit
git commit -m "your message"

# Push (use Option A or B above with a valid PAT)
git push https://maraprikkripa:<YOUR_PAT>@github.com/maraprikkripa/dbt-mcp-demo.git main
```

---

## Repo structure (what's in GitHub)

```
dbt-mcp-demo/
├── CLAUDE.md                  ← workspace conventions
├── SETUP.md                   ← full multi-phase setup guide
├── COMMANDS.md                ← workspace command reference
├── phase4-prompt.md           ← DuckDB 4-layer build prompt
├── .mcp.json                  ← MCP server config (dbt + dbt-bq)
├── .gitignore                 ← keys/, target/, *.duckdb excluded
│
├── jaffle_shop/               ← DuckDB project (dbt-fusion)
│   ├── CLAUDE.md / COMMANDS.md / SETUP.md / PROMPT.md
│   ├── models/ seeds/ macros/
│   └── .claude/commands/      ← 8 dbt agent skills
│
├── jaffle_shop_bq/            ← BigQuery project (dbt-fusion local)
│   ├── CLAUDE.md / COMMANDS.md / SETUP.md / PROMPT.md
│   └── models/ seeds/ macros/
│
└── jaffle_shop_cloud/         ← BigQuery project (dbt Cloud)
    ├── CLAUDE.md / COMMANDS.md / SETUP.md / PROMPT.md
    └── models/ seeds/ macros/
```

## What is NOT in GitHub

```
keys/                          ← service account JSON key (local only)
target/                        ← dbt build artifacts
dbt_packages/                  ← installed packages (run dbt deps to restore)
*.duckdb                       ← local DuckDB database file
run_logs/                      ← build/test log files
```

---

## When PAT expires

Generate a new one following the steps above. The scope only needs `repo`.
