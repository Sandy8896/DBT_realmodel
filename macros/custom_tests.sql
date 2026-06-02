-- ============================================================
-- GENERIC (SCHEMA) TEST: assert_positive_value
--
-- A custom test you can apply to any numeric column in schema.yml:
--
--   columns:
--     - name: amount
--       tests:
--         - assert_positive_value
--
-- dbt will call this macro and FAIL if any row returns.
-- (Generic tests fail when the SELECT returns > 0 rows.)
-- ============================================================

{% test assert_positive_value(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} <= 0

{% endtest %}


-- ============================================================
-- GENERIC TEST: assert_no_future_dates
-- Fails if any date column has a future date.
-- Usage in schema.yml:
--   tests:
--     - assert_no_future_dates
-- ============================================================

{% test assert_no_future_dates(model, column_name) %}

select *
from {{ model }}
where {{ column_name }} > current_date

{% endtest %}
