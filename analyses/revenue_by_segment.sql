-- ============================================================
-- ANALYSIS FILE: analyses/revenue_by_segment.sql
--
-- Analyses are NOT run by `dbt run`. They are:
--   • Compiled by `dbt compile`  (SQL written to target/compiled/)
--   • Run manually in your SQL client
--
-- USE CASE:  Ad-hoc exploration, one-off reports, or QA queries
--            that still benefit from ref() and macros.
-- ============================================================

-- Monthly revenue breakdown by customer segment
select
    extract(year  from order_date) as year,
    extract(month from order_date) as month,
    customer_segment,
    count(distinct customer_id)    as customers,
    count(*)                       as orders,
    sum(revenue)                   as net_revenue,
    avg(amount)                    as avg_order_value

from {{ ref('fct_orders') }}
where status = 'completed'
group by 1, 2, 3
order by 1, 2, net_revenue desc
