-- ============================================================
-- MATERIALIZATION: EPHEMERAL
--
-- WHY:  Ephemeral models are NOT materialized in the DB at all.
--       dbt inlines them as a CTE wherever they are ref()-ed.
--       Perfect for intermediate transformation logic you want
--       to reuse WITHOUT creating an extra table/view.
--
-- HOW:  Any model that calls  ref('int_customer_order_stats')
--       gets this SQL inlined as a CTE — invisible to the DB.
-- ============================================================

{{
  config(
    materialized = 'ephemeral'
  )
}}

with orders as (

    select * from {{ ref('stg_orders') }}

),

agg as (

    select
        customer_id,
        count(*)                                         as total_orders,
        sum(amount)                                      as total_spend,
        avg(amount)                                      as avg_order_value,
        min(order_date)                                  as first_order_date,
        max(order_date)                                  as last_order_date,
        count(*) filter (where status = 'completed')    as completed_orders,
        count(*) filter (where status = 'cancelled')    as cancelled_orders,

        -- Days between first and last order (customer tenure)
        (max(order_date) - min(order_date))              as days_active

    from orders
    group by 1

)

select * from agg
