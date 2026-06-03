-- ============================================================
-- MATERIALIZATION: TABLE
--
-- WHY:  Dimension tables are queried heavily by BI tools.
--       Materializing as a TABLE means the query is pre-run;
--       end users get instant results.
--
-- WHEN TO USE:  Relatively static data, high query volume,
--               or when downstream tools can't handle views.
-- ============================================================

{{
  config(
    materialized = 'table',
    tags         = ['marts', 'dimensions']
  )
}}

with customers as (

    select * from {{ ref('stg_customers') }}

),

-- ref() on an EPHEMERAL model → dbt inlines it as a CTE
order_stats as (

    select * from {{ ref('int_customer_order_stats') }}

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
        {{ customer_segment('o.total_spend', 'o.total_orders') }} as segment,

        -- Metadata
        current_timestamp()                           as dbt_updated_at

    from customers c
    left join order_stats o using (customer_id)

)

select * from final
