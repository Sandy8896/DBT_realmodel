-- ============================================================
-- SINGULAR TEST: cancelled orders must have zero revenue
-- ============================================================

select
    order_id,
    status,
    revenue
from {{ ref('fct_orders') }}
where status = 'cancelled'
  and revenue > 0
