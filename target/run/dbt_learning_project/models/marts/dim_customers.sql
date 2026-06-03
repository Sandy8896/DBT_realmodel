
  
    

create or replace transient table DBT_TEST.marts.dim_customers
    
    
    
    as (-- ============================================================
-- MATERIALIZATION: TABLE
--
-- WHY:  Dimension tables are queried heavily by BI tools.
--       Materializing as a TABLE means the query is pre-run;
--       end users get instant results.
--
-- WHEN TO USE:  Relatively static data, high query volume,
--               or when downstream tools can't handle views.
-- ============================================================



with  __dbt__cte__int_customer_order_stats as (


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
), customers as (

    select * from DBT_TEST.staging.stg_customers

),

-- ref() on an EPHEMERAL model → dbt inlines it as a CTE
order_stats as (

    select * from __dbt__cte__int_customer_order_stats

),

final as (

    select
        c.customer_sk,
        c.customer_id,
        c.first_name,
        c.last_name,
        c.email,
        c.country,
        c.signup_date,

        -- Enrichment from ephemeral intermediate
        coalesce(o.total_orders,      0)            as total_orders,
        coalesce(o.total_spend,       0)            as lifetime_value,
        coalesce(o.avg_order_value,   0)            as avg_order_value,
        o.first_order_date,
        o.last_order_date,
        coalesce(o.completed_orders,  0)            as completed_orders,
        coalesce(o.cancelled_orders,  0)            as cancelled_orders,

        -- Derived: customer segment using a macro
        
    case
        when o.total_spend >= 500 and o.total_orders >= 3  then 'VIP'
        when o.total_spend >= 200                            then 'Regular'
        when o.total_orders = 0 or o.total_spend is null   then 'New'
        else                                                        'At-Risk'
    end
 as segment,

        -- Metadata
        current_timestamp()                           as dbt_updated_at

    from customers c
    left join order_stats o using (customer_id)

)

select * from final
    )
;


  