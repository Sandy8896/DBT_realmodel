# 🎓 dbt Learning Project — Full Feature Walkthrough

A self-contained project to get hands-on with **every major dbt feature**.
Uses **DuckDB** as the database — no external DB setup required.

---

## 📁 Project Structure

```
dbt_learning_project/
│
├── dbt_project.yml              ← Main project config (materializations, paths)
├── profiles.yml                 ← DB connection (copy to ~/.dbt/profiles.yml)
│
├── seeds/                       ◄ FEATURE 1: Seeds
│   ├── raw_customers.csv
│   ├── raw_orders.csv
│   ├── raw_events.csv
│   └── schema.yml               ← Tests on seed columns
│
├── models/
│   ├── staging/                 ◄ FEATURE 2: VIEW materialization
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql
│   │   ├── stg_events.sql
│   │   └── schema.yml
│   │
│   ├── intermediate/            ◄ FEATURE 3: EPHEMERAL materialization
│   │   └── int_customer_order_stats.sql
│   │
│   └── marts/                   ◄ FEATURE 4: TABLE + INCREMENTAL
│       ├── dim_customers.sql    ← TABLE
│       ├── fct_orders.sql       ← TABLE
│       ├── fct_events_incremental.sql          ← INCREMENTAL (append)
│       ├── fct_daily_revenue_incremental.sql   ← INCREMENTAL (delete+insert)
│       └── schema.yml
│
├── macros/                      ◄ FEATURE 5: Macros
│   ├── custom_macros.sql        ← 8 reusable macros
│   └── custom_tests.sql         ← Custom generic tests
│
├── snapshots/                   ◄ FEATURE 6: Snapshots (SCD Type 2)
│   ├── snap_customers.sql       ← timestamp strategy
│   └── snap_orders.sql          ← check strategy
│
├── tests/                       ◄ FEATURE 7: Singular tests
│   ├── assert_vip_customers_high_spend.sql
│   └── assert_cancelled_orders_zero_revenue.sql
│
└── analyses/                    ◄ FEATURE 8: Analyses (compiled, not run)
    └── revenue_by_segment.sql
```

---

## 🚀 Quick Start

### 1. Install dbt with DuckDB adapter
```bash
pip install dbt-duckdb
```

### 2. Set up your profile
```bash
cp profiles.yml ~/.dbt/profiles.yml
# or just run from the project directory — dbt looks here too
```

### 3. Test your connection
```bash
cd dbt_learning_project
dbt debug
```

---

## 📚 Step-by-Step Feature Exercises

---

### 🌱 FEATURE 1: Seeds — Load CSV data into the DB

Seeds let you load static CSV files as database tables.
Use them for lookup tables, test data, or raw source data.

```bash
# Load all CSVs into the database
dbt seed

# Load only one seed
dbt seed --select raw_customers

# Full refresh (truncate + reload)
dbt seed --full-refresh
```

**What to observe:**
- A `raw` schema is created with tables: `raw_customers`, `raw_orders`, `raw_events`
- Run `dbt test --select source:raw_customers` to validate seed data quality

---

### 👁️ FEATURE 2: VIEW Materialization — Staging Layer

Views are SQL stored as a query definition, not data.
Every time you SELECT from a view, the underlying SQL runs.

```bash
dbt run --select staging
```

**In `stg_customers.sql`:**
```sql
{{ config(materialized = 'view') }}
```

**When to use VIEW:**
- Staging layer (lightweight transforms)
- Data changes frequently
- Low query volume

**Inspect:**
```sql
-- In DuckDB, views appear in information_schema
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'staging';
```

---

### 👻 FEATURE 3: EPHEMERAL Materialization — Intermediate Layer

Ephemeral models are **never written to the DB**.
dbt inlines them as a CTE inside the model that refs them.

```bash
# Running dim_customers will automatically inline int_customer_order_stats
dbt run --select dim_customers
```

**In `int_customer_order_stats.sql`:**
```sql
{{ config(materialized = 'ephemeral') }}
```

**How to verify it's ephemeral:**
```bash
dbt compile --select int_customer_order_stats
# Check target/compiled/ — you'll see the CTE inlined into dim_customers.sql
cat target/compiled/dbt_learning_project/models/marts/dim_customers.sql
```

**When to use EPHEMERAL:**
- Intermediate logic reused by multiple models
- You want modularity without DB clutter
- The intermediate result is only useful as a stepping stone

---

### 🗄️ FEATURE 4a: TABLE Materialization — Mart Layer

Tables store the full query result physically.
Best for dimension/fact tables queried heavily by BI tools.

```bash
dbt run --select dim_customers fct_orders
```

**In `dim_customers.sql`:**
```sql
{{ config(materialized = 'table') }}
```

**When to use TABLE:**
- Downstream BI tools (Tableau, Power BI, Looker)
- Expensive aggregations you don't want re-run per query
- Data that changes infrequently (dimensions)

---

### ⚡ FEATURE 4b: INCREMENTAL Materialization — Append Strategy

Processes only NEW rows. Perfect for append-only event logs.

```bash
# First run: full load
dbt run --select fct_events_incremental

# Simulate a second run (only new events since last max timestamp)
dbt run --select fct_events_incremental

# Force full refresh (rebuild from scratch)
dbt run --select fct_events_incremental --full-refresh
```

**Key code in `fct_events_incremental.sql`:**
```sql
{{ config(
    materialized = 'incremental',
    unique_key   = 'event_id',
    incremental_strategy = 'append'
) }}

{% if is_incremental() %}
    where event_ts > (select max(event_ts) from {{ this }})
{% endif %}
```

**`{{ this }}`** = reference to the existing table being incrementally built.
**`is_incremental()`** = TRUE on 2nd+ runs, FALSE on first run.

---

### ⚡ FEATURE 4c: INCREMENTAL — delete+insert Strategy

Re-processes a rolling window of dates. Handles late-arriving data.

```bash
dbt run --select fct_daily_revenue_incremental
```

**In `fct_daily_revenue_incremental.sql`:**
```sql
{{ config(
    materialized         = 'incremental',
    unique_key           = 'order_date',
    incremental_strategy = 'delete+insert'
) }}

{% if is_incremental() %}
    -- Reprocess last 3 days to catch updates
    where order_date >= (select max(order_date) - interval '3 days' from {{ this }})
{% endif %}
```

**Incremental Strategy Comparison:**

| Strategy | How it works | Best for |
|----------|-------------|----------|
| `append` | INSERT new rows only | Immutable event logs |
| `merge` | UPSERT by unique_key | Snowflake, BigQuery |
| `delete+insert` | DELETE matching partition, re-INSERT | Late-arriving data |
| `insert_overwrite` | Overwrite whole partition | Spark, BigQuery partitioned |

---

### 🔧 FEATURE 5: Macros — Reusable Jinja Functions

Macros generate SQL dynamically. They're like functions in Python.

```bash
# Compile to see generated SQL
dbt compile --select stg_customers
cat target/compiled/dbt_learning_project/models/staging/stg_customers.sql
```

**8 macros in `macros/custom_macros.sql`:**

| Macro | What it does |
|-------|-------------|
| `clean_email(col)` | lowercase + trim |
| `categorize_order_amount(col)` | Small / Medium / Large label |
| `customer_segment(spend, orders)` | VIP / Regular / At-Risk / New |
| `dbt_utils_surrogate_key([cols])` | MD5 hash surrogate key |
| `cents_to_dollars(col, precision)` | Unit conversion |
| `log_info(msg)` | Print during run |
| `generate_schema_name(...)` | Override dbt's schema naming |
| `union_tables([list])` | Dynamic UNION ALL |

**Call from SQL:**
```sql
{{ clean_email('email') }}
{{ customer_segment('total_spend', 'total_orders') }}
```

**Call from command line:**
```bash
dbt run-operation log_info --args '{"message": "Hello from CLI!"}'
```

---

### 📸 FEATURE 6: Snapshots — SCD Type 2

Snapshots record historical changes to rows over time.
Run them on a schedule (daily/hourly) to build a change history.

```bash
# First snapshot run — records current state
dbt snapshot

# Simulate a change: edit raw_customers.csv (change Alice's country to UK)
# Then run again:
dbt snapshot

# Query the history
# In DuckDB:
# SELECT * FROM snapshots.snap_customers ORDER BY customer_id, dbt_valid_from;
```

**Extra columns added by dbt:**

| Column | Meaning |
|--------|---------|
| `dbt_scd_id` | Unique ID per row version |
| `dbt_valid_from` | When this version became active |
| `dbt_valid_to` | When this version was replaced (NULL = current) |
| `dbt_updated_at` | Timestamp of snapshot run |

**Two strategies:**

```sql
-- strategy: timestamp  (uses updated_at column)
strategy = 'timestamp', updated_at = 'updated_at'

-- strategy: check  (hashes specific columns)
strategy = 'check', check_cols = ['status', 'amount']
```

---

### ✅ FEATURE 7: Tests

```bash
# Run ALL tests
dbt test

# Test only seeds
dbt test --select raw_customers

# Test only a model
dbt test --select dim_customers

# Run tests + models together
dbt build --select dim_customers
```

**3 types of tests:**

**1. Built-in generic tests** (in schema.yml):
```yaml
tests: [unique, not_null, accepted_values, relationships]
```

**2. Custom generic tests** (`macros/custom_tests.sql`):
```yaml
tests:
  - assert_positive_value
  - assert_no_future_dates
```

**3. Singular tests** (SQL files in `tests/`):
```sql
-- Fails if any row is returned
SELECT * FROM {{ ref('dim_customers') }} WHERE segment = 'VIP' AND lifetime_value < 500
```

---

### 📊 FEATURE 8: Analyses — Ad-hoc SQL with ref()

```bash
# Compile (generates SQL in target/compiled/) — does NOT run
dbt compile

# Then run the compiled SQL in your SQL client
cat target/compiled/dbt_learning_project/analyses/revenue_by_segment.sql
```

---

### 📖 FEATURE 9: Documentation

```bash
# Generate docs
dbt docs generate

# Serve locally (opens browser at localhost:8080)
dbt docs serve
```

---

## 🏃 Run Everything At Once

```bash
# Full pipeline: seed → run → test → snapshot
dbt seed && dbt run && dbt test && dbt snapshot

# Or use dbt build (seed + run + test in one command, respects DAG order)
dbt build
```

---

## 🔑 Key dbt Concepts Cheat Sheet

```
ref('model_name')        → Builds DAG + resolves schema/table name
source('src', 'tbl')     → References raw source tables
{{ this }}               → Current model's table (used in incremental)
is_incremental()         → TRUE on 2nd+ run of an incremental model
{{ config(...) }}        → Set materialization, tags, etc. per model
{{ var('name') }}        → Access variables from dbt_project.yml or CLI
{{ env_var('VAR') }}     → Read environment variables
dbt_project.yml          → Global defaults for all models
schema.yml               → Per-model docs + tests
```
