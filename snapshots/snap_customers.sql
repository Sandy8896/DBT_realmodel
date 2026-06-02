-- ============================================================
-- SNAPSHOT: snap_customers  (SCD Type 2)
--
-- WHY:  Snapshots capture HISTORICAL CHANGES to a row.
--       Without snapshots, when a customer updates their email
--       or country, the old value is lost forever.
--
-- WHAT IT CREATES:  A table with extra columns:
--   dbt_scd_id      → unique key per version
--   dbt_updated_at  → when this version was recorded
--   dbt_valid_from  → when this version became active
--   dbt_valid_to    → when this version was superseded
--                     (NULL = current/active version)
--
-- STRATEGY: timestamp
--   dbt compares `updated_at` to detect changes.
--   If updated_at changed → new row is inserted with the
--   old row's dbt_valid_to set to now.
--
-- ALTERNATIVE STRATEGY: check
--   strategy = 'check'
--   check_cols = ['email', 'country']  ← dbt diffs these columns
--   Use when your source has no reliable updated_at column.
-- ============================================================

{% snapshot snap_customers %}

{{
    config(
        target_schema  = 'snapshots',
        strategy       = 'timestamp',
        unique_key     = 'customer_id',
        updated_at     = 'updated_at',
        invalidate_hard_deletes = true   -- marks deleted rows as expired
    )
}}

-- The SELECT here is what dbt monitors for changes.
-- Point it at the raw or staging source.
select
    customer_id,
    first_name,
    last_name,
    email,
    country,
    signup_date,
    updated_at
from {{ ref('raw_customers') }}

{% endsnapshot %}
