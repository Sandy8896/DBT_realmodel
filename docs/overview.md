{% docs __overview__ %}

# 🎓 dbt Learning Project

A hands-on project that demonstrates **every major dbt feature** using a simple e-commerce domain.

## Data Flow

```
CSV Seeds (raw)
    ↓  dbt seed
Staging Models (VIEW)      ← stg_customers, stg_orders, stg_events
    ↓  ref()
Intermediate (EPHEMERAL)   ← int_customer_order_stats  [inlined as CTE]
    ↓  ref()
Mart Models
    ├── dim_customers        (TABLE)
    ├── fct_orders           (TABLE)
    ├── fct_events_incremental          (INCREMENTAL – append)
    └── fct_daily_revenue_incremental   (INCREMENTAL – delete+insert)

Snapshots (SCD Type 2)
    ├── snap_customers  (timestamp strategy)
    └── snap_orders     (check strategy)
```

## Features Covered

| Feature | File(s) |
|---------|---------|
| Seeds | `seeds/raw_*.csv` |
| VIEW materialization | `models/staging/` |
| TABLE materialization | `models/marts/dim_customers.sql`, `fct_orders.sql` |
| EPHEMERAL materialization | `models/intermediate/` |
| INCREMENTAL – append | `models/marts/fct_events_incremental.sql` |
| INCREMENTAL – delete+insert | `models/marts/fct_daily_revenue_incremental.sql` |
| Macros | `macros/custom_macros.sql` |
| Generic Tests | `macros/custom_tests.sql` |
| Singular Tests | `tests/` |
| Snapshots (timestamp) | `snapshots/snap_customers.sql` |
| Snapshots (check) | `snapshots/snap_orders.sql` |
| Analyses | `analyses/` |
| Schema tests | `*/schema.yml` |
| Documentation | `docs/overview.md` |

{% enddocs %}
