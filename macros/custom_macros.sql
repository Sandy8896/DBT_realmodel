-- ============================================================
-- macros/custom_macros.sql
--
-- Macros are Jinja functions that generate SQL.
-- They are reusable across all models.
-- Call them with:  {{ macro_name(args) }}
-- ============================================================


-- ────────────────────────────────────────────
-- MACRO 1: clean_email
-- Trims whitespace and lowercases an email column.
-- Usage:  {{ clean_email('email') }}
-- ────────────────────────────────────────────
{% macro clean_email(column_name) %}
    lower(trim({{ column_name }}))
{% endmacro %}


-- ────────────────────────────────────────────
-- MACRO 2: categorize_order_amount
-- Returns a text label based on order amount.
-- Usage:  {{ categorize_order_amount('amount') }}
-- ────────────────────────────────────────────
{% macro categorize_order_amount(amount_col) %}
    case
        when {{ amount_col }} >= 400  then 'Large'
        when {{ amount_col }} >= 150  then 'Medium'
        else                               'Small'
    end
{% endmacro %}


-- ────────────────────────────────────────────
-- MACRO 3: customer_segment
-- Segments customer based on spend + order count.
-- Usage:  {{ customer_segment('spend_col', 'orders_col') }}
-- ────────────────────────────────────────────
{% macro customer_segment(spend_col, orders_col) %}
    case
        when {{ spend_col }} >= 500 and {{ orders_col }} >= 3  then 'VIP'
        when {{ spend_col }} >= 200                            then 'Regular'
        when {{ orders_col }} = 0 or {{ spend_col }} is null   then 'New'
        else                                                        'At-Risk'
    end
{% endmacro %}


-- ────────────────────────────────────────────
-- MACRO 4: dbt_utils_surrogate_key (simplified)
-- Generates a surrogate key by hashing a list of columns.
-- Usage:  {{ dbt_utils_surrogate_key(['col1', 'col2']) }}
-- ────────────────────────────────────────────
{% macro dbt_utils_surrogate_key(column_names) %}
    md5(
        concat_ws('|',
            {% for col in column_names %}
                cast({{ col }} as varchar)
                {% if not loop.last %}, {% endif %}
            {% endfor %}
        )
    )
{% endmacro %}


-- ────────────────────────────────────────────
-- MACRO 5: cents_to_dollars
-- Converts integer cents to decimal dollars.
-- Usage:  {{ cents_to_dollars('amount_cents') }}
-- ────────────────────────────────────────────
{% macro cents_to_dollars(column_name, precision=2) %}
    round({{ column_name }} / 100.0, {{ precision }})
{% endmacro %}


-- ────────────────────────────────────────────
-- MACRO 6: log_info  (prints during dbt run)
-- Demonstrates {{ log() }} built-in
-- Usage:  {{ log_info('Loading events...') }}
-- ────────────────────────────────────────────
{% macro log_info(message) %}
    {{ log("[INFO] " ~ message, info=true) }}
{% endmacro %}


-- ────────────────────────────────────────────
-- MACRO 7: generate_schema_name  (OVERRIDE)
-- dbt's built-in: controls custom schema naming.
-- Without this, dbt prefixes your schema with the target schema.
-- With this: we use the custom schema name directly.
-- ────────────────────────────────────────────
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}


-- ────────────────────────────────────────────
-- MACRO 8: union_tables (looping macro example)
-- Dynamically UNIONs a list of table refs.
-- Usage:  {{ union_tables(['table_a', 'table_b']) }}
-- ────────────────────────────────────────────
{% macro union_tables(table_list) %}
    {% for tbl in table_list %}
        select *, '{{ tbl }}' as source_table
        from {{ ref(tbl) }}
        {% if not loop.last %} union all {% endif %}
    {% endfor %}
{% endmacro %}
