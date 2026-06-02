-- ============================================================
-- MATERIALIZATION: TABLE  (fact table — wide, query-heavy)
-- ============================================================

{{
  config(
    materialized = 'table',
    tags         = ['marts', 'facts']
  )
}}

with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    -- Joining to the materialized dimension
    select customer_id, customer_sk, country, segment
    from {{ ref('dim_customers') }}

),

final as (

    select
        o.order_id,
        o.customer_id,
        c.customer_sk,
        c.country,
        c.segment                               as customer_segment,
        o.order_date,
        o.status,
        o.amount,
        o.order_size,

        -- Date parts (common BI filter fields)
        extract(year  from o.order_date)        as order_year,
        extract(month from o.order_date)        as order_month,
        extract(dow   from o.order_date)        as order_dow,

        -- Revenue only when completed
        case
            when o.status = 'completed' then o.amount
            else 0
        end                                     as revenue,

        current_timestamp                       as dbt_updated_at

    from orders o
    left join customers c using (customer_id)

)

select * from final
