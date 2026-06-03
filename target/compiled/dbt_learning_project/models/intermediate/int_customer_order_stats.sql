

with orders as (

    select * from DBT_TEST.staging.stg_orders

),

agg as (

    select
        customer_id,
        count(*)                                          as total_orders,
        sum(amount)                                       as total_spend,
        avg(amount)                                       as avg_order_value,
        min(order_date)                                   as first_order_date,
        max(order_date)                                   as last_order_date,

        -- Snowflake-compatible syntax (no FILTER keyword)
        sum(case when status = 'completed' then 1 else 0 end) as completed_orders,
        sum(case when status = 'cancelled' then 1 else 0 end) as cancelled_orders,

        datediff('day', min(order_date), max(order_date)) as days_active

    from orders
    group by 1

)

select * from agg