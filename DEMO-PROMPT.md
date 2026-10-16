# Antigravity Demo Prompt

Copy and paste this entire prompt to begin the guided demo.

---

You are a guided demo assistant helping me walk through a live partner demonstration of dbt + Antigravity. We will complete a series of steps together to build out a new analytics feature from scratch in our existing jaffle_shop project. The underlying data is in BigQuery/DuckDB.

Important instructions for how you should behave throughout this demo:

Complete ONE step at a time. After each step, pause and tell me exactly what was created or changed. Tell me what to do next (e.g. "run dbt build, check the output, confirm you you're ready to continue"). Do not proceed to the next step until I confirm. If anything fails, help me debug it before moving on. Occasionally briefly explain WHY we're doing this so I can narrate it to a live audience.

---

## STEP 1 — Inspect the project and understand the data

Before we build anything, inspect my dbt project and find the following:

- Locate any models that reference `order_date` or `location_id`
- Identify the grain, data tests, and location values used across those models
- Summarize what you found so I can confirm the seed file we're about to build will align with the existing pipeline

After this step: Tell me what you found about the range of `order_date`, distinct `location_id` values, and the grain of the data. Wait for me to confirm before continuing.

---

## STEP 2 — Create a regional sales targets seed file

Tell me what you learned in Step 1 about `order_date` and `location_id`. Then create the following:

- One row per `location_id` per month aligned to the actual date range from the existing data (in `YYYY-MM-DD` date format)
- A `monthly_target` column based on the actual historical revenue for each location, with a 10% growth rate applied (i.e. target = historical average monthly revenue × 1.1)
- Include columns: `location_id`, `target_month` (first day of the month in the correct date format), `monthly_target`
- Make the data statistically plausible — targets should vary by location proportional to their historical values, not be uniform
- Also create the corresponding schema.yml entry with column descriptions

After this step: Show me the first 10 rows of the seed file and the schema.yml entry. Tell me to run `dbt seed` and confirm it loads cleanly before we continue.

---

## STEP 3 — Generate the staging and marts models

Using the seed file and the existing orders data, create two new dbt models:

**Model 1:** `stg_regional_targets.sql`

Lightly transform the seed file — casting columns and making naming conventions consistent with the rest of the project.

Add a surrogate key using `dbt_utils.generate_surrogate_key`.

**Model 2:** `mart_regional_revenue_vs_target.sql`

Join the orders model to `regional_sales_targets` on `location_id` and month.

Calculate the following metrics per location:

- `monthly_revenue_target`
- `monthly_revenue_attainment` (actual / target)
- `monthly_vs_target_delta` (actual − target)

Apply correct `ref()` syntax. Create a dbt block with `materialized='table'`, and add all column definitions to a `.yml` file.

After this step: Show me both models and confirm the dependencies. Tell me to run `dbt build --select` to build the models and confirm all models pass before continuing.

---

## STEP 4 — Add unit tests

Using the `adding-dbt-unit-test` dbt skill, add a unit test for: `mart_regional_vs_target`

The join logic is correct — a location with known revenue and a known target should pass the attainment percentage calculation. Confirm the target does not cause a divide-by-zero error.

Structure the unit tests with realistic mock input fixtures and verify delta calculations are as expected.

After this step: Show me the unit test results and confirm all tests pass successfully before continuing.

---

## STEP 5 — Create a D3.js visualization as a standalone HTML page

Create a self-contained HTML + D3 file with a bar chart showing `regional_revenue_vs_target`. Embed the sample data (use the data from `dbt show`) — specifically the 3–4 location combo and the revenue figures.

- Renders an interactive grouped bar chart showing actual vs target revenue
- Uses a color scale to indicate performance: green if on/above target, amber if within 20% below, red if more than 20% below
- Includes a month selector dropdown to filter by `target_month`
- Includes a tooltip on hover showing: location, month, actual revenue, target, and attainment percentage
- Uses sample data that mirrors the shape and values of `mart_regional_revenue_vs_target`
- It renders immediately in a browser — no live DB connection, no build step, no external CSS frameworks

After this step: Tell me to open `regional_revenue_vs_target.html` in a browser and confirm it works.

---

## STEP 6 — Create a semantic layer definition

**Metric:** `revenue_attainment`

**Description:** Percentage of monthly revenue target achieved per location

**Measure:** `revenue_attainment_pct`

**Filters:** Exclude any rows where `monthly_revenue_target` is zero

Write the dbt semantic layer YAML definition. Explain to me in one sentence how I would activate this step to the audience — specifically who this is for: governance and AI querying.

---

## STEP 7 — Run Advanced CI and regression

After this step, explain:

- Uses `--state`, `--select state:modified`, seeds, and relevant tests
- Summarize the models, seeds, and tests that were created or changed in this session

After step: List every artifact that would be added in a future merge. Explain what dbt's slim CI (`--select state:modified+1`) would build for this change. Would it be generated on CI in dbt Cloud and confirm what a developer on this project would need to do successfully before continuing.

---

## STEP 8 — State builds and saved states

Explain how to use the `--select state:modified+` command.

Explain how `dbt defer` works. Give me the command a developer on this project would use — now that AI is generating and changing models faster than humans.

After this step: Give me the correct `dbt build --select state:modified+` command to confirm the affected models. Explain to me in 2–3 sentences how I would explain this to the audience — specifically how the trust this warehouse cost contributes to the trust theme of the session.

---

## Demo Complete

After each major step, summarize what was built — I'll confirm before moving on.

Write a brief, clean summary of everything that was created: models built, tests added, visualizations created in the session — suitable for a closing slide talking track.
