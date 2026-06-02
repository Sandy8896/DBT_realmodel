-- ============================================================
-- MATERIALIZATION: INCREMENTAL  — strategy: delete+insert
--
-- WHY:  Daily revenue can be recomputed if a past order is
--       updated (status changed, refund). We need to REPLACE
--       old daily rows, not just append.
--
-- STRATEGIES compared:
--   append        → INSERT only. Fast. No dedup.
--   merge         → Upsert by unique_key. Best for Snowflake/BQ.
--   delete+insert → Delete matching partition, then insert.
--                   Best for BigQuery with partition_by, or when
--                   merge is not supported.
--   insert_overwrite → Overwrites whole partition. Spark/BigQuery.
--
-- Here we use delete+insert, partitioned by order_date.
-- ============================================================

{{
  config(
    materialized         = 'incremental',
    unique_key           = 'order_date',
    incremental_strategy = 'delete+insert',   -- replaces stale date partitions
    tags                 = ['marts', 'incremental', 'daily']
  )
}}

with orders as (

    select * from {{ ref('stg_orders') }}

    {% if is_incremental() %}
        -- Only reprocess dates that have new/changed orders
        -- (look back 3 days to catch late-arriving records)
        where order_date >= (
            select dateadd(day, -3, max(order_date)) from {{ this }}
        )
    {% endif %}

),

daily as (

    select
        order_date,
        count(*)                                              as total_orders,
        count(*) filter (where status = 'completed')         as completed_orders,
        count(*) filter (where status = 'cancelled')         as cancelled_orders,
        sum(amount)                                           as gross_revenue,
        sum(case when status = 'completed' then amount end)  as net_revenue,
        avg(amount)                                           as avg_order_value,
        count(distinct customer_id)                           as unique_customers,
        current_timestamp                                     as dbt_updated_at

    from orders
    group by 1

)

select * from daily
