-- ============================================================
-- MATERIALIZATION: INCREMENTAL  — strategy: append (default)
--
-- WHY:  Event tables grow forever. A full-refresh every run
--       is too slow. Incremental processes only NEW rows.
--
-- HOW IT WORKS:
--   1st run  → dbt runs the full SELECT and creates the table.
--   2nd+ run → dbt adds only rows where event_ts > last max.
--
-- KEY BLOCKS:
--   is_incremental()  → Jinja macro that returns TRUE only
--                        on non-first runs (table exists).
--   unique_key        → dbt uses this to UPSERT duplicates
--                        instead of inserting them twice.
--
-- STRATEGY: append  (no merge/delete-insert; just INSERT)
-- ============================================================

{{
  config(
    materialized       = 'incremental',
    unique_key         = 'event_id',
    incremental_strategy = 'append',      -- simplest: only adds new rows
    tags               = ['marts', 'incremental']
  )
}}

with events as (

    select * from {{ ref('stg_events') }}

    -- ── THE INCREMENTAL FILTER ──────────────────────────────
    -- is_incremental() is FALSE on first run (full load)
    -- is_incremental() is TRUE on subsequent runs (delta only)
    {% if is_incremental() %}

        where event_ts > (
            -- Find the latest timestamp already in the table
            select max(event_ts) from {{ this }}
        )

    {% endif %}
    -- ────────────────────────────────────────────────────────

),

enriched as (

    select
        e.event_id,
        e.customer_id,
        e.event_type,
        e.event_ts,
        e.event_date,
        e.page,

        -- Join to dim for country enrichment at event time
        c.country,
        c.segment                       as customer_segment,

        current_timestamp               as dbt_loaded_at

    from events e
    left join {{ ref('dim_customers') }} c using (customer_id)

)

select * from enriched
