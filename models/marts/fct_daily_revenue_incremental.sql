{{
    config(
        materialized='incremental',
        unique_key='order_date',
        tags=['marts', 'incremental']
    )
}}

with orders as (

    select *
    from {{ ref('stg_orders') }}

    {% if is_incremental() %}

        -- Reprocess the last 3 days to capture late-arriving updates
        where order_date >= (
            select dateadd(day, -3, max(order_date))
            from {{ this }}
        )

    {% endif %}

),

daily as (

    select
        order_date,

        count(*) as total_orders,

        sum(
            case
                when status = 'completed' then 1
                else 0
            end
        ) as completed_orders,

        sum(
            case
                when status = 'cancelled' then 1
                else 0
            end
        ) as cancelled_orders,

        coalesce(sum(amount), 0) as gross_revenue,

        coalesce(
            sum(
                case
                    when status = 'completed' then amount
                    else 0
                end
            ),
            0
        ) as net_revenue,

        avg(amount) as avg_order_value,

        count(distinct customer_id) as unique_customers,

        current_timestamp() as dbt_updated_at

    from orders
    group by order_date

)

select *
from daily