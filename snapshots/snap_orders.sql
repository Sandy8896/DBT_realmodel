-- ============================================================
-- SNAPSHOT: snap_orders  — strategy: CHECK
--
-- WHY:  Order status (pending→completed→returned) changes but
--       not all source systems update an `updated_at` reliably.
--
-- STRATEGY: check
--   dbt hashes the specified columns each run.
--   If the hash changes → new snapshot row created.
-- ============================================================

{% snapshot snap_orders %}

{{
    config(
        target_schema = 'snapshots',
        strategy      = 'check',
        unique_key    = 'order_id',
        check_cols    = ['status', 'amount'],   -- monitor these for changes
        invalidate_hard_deletes = false
    )
}}

select
    order_id,
    customer_id,
    order_date,
    status,
    amount,
    updated_at
from {{ ref('raw_orders') }}

{% endsnapshot %}
