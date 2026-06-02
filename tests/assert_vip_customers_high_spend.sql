-- ============================================================
-- SINGULAR TEST: tests/assert_vip_customers_high_spend.sql
--
-- Singular tests are standalone SQL files in the tests/ folder.
-- They FAIL if they return any rows.
--
-- This test checks that no customer labelled 'VIP' has
-- a lifetime_value below $500 (business rule validation).
-- ============================================================

select
    customer_id,
    segment,
    lifetime_value
from {{ ref('dim_customers') }}
where segment = 'VIP'
  and lifetime_value < 500
