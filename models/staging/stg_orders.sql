-- ============================================================
-- MATERIALIZATION: VIEW
-- ============================================================

{{
  config(
    materialized = 'view',
    tags         = ['staging', 'orders']
  )
}}

with source as (

    select * from {{ ref('raw_orders') }}

),

cleaned as (

    select
        order_id,
        customer_id,
        cast(order_date  as date)      as order_date,
        lower(status)                  as status,
        cast(amount      as numeric)   as amount,
        cast(updated_at  as timestamp) as updated_at,

        -- Label orders using a custom macro
        {{ categorize_order_amount('amount') }} as order_size

    from source

)

select * from cleaned
