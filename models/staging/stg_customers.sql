-- ============================================================
-- MATERIALIZATION: VIEW  (set at folder level in dbt_project.yml)
-- WHY: Staging models are cheap SELECT transforms; we want
--      them always fresh without storing redundant data.
-- ============================================================

{{
  config(
    materialized = 'view',
    tags         = ['staging', 'customers']
  )
}}

with source as (

    -- ref() builds the DAG dependency on the seed
    select * from {{ ref('raw_customers') }}

),

renamed as (

    select
        customer_id,
        first_name,
        last_name,
        -- Macro call: clean + lowercase email
        {{ clean_email('email') }}          as email,
        upper(country)                       as country,
        cast(signup_date  as date)           as signup_date,
        cast(updated_at   as timestamp)      as updated_at,
        -- Macro call: generate a surrogate key
        {{ dbt_utils_surrogate_key(['customer_id']) }} as customer_sk

    from source

)

select * from renamed
