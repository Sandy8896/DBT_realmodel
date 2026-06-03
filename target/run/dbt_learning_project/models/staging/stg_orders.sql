
  create or replace   view DBT_TEST.staging.stg_orders
  
  
  
  
  as (
    -- ============================================================
-- MATERIALIZATION: VIEW
-- ============================================================



with source as (

    select * from DBT_TEST.raw.raw_orders

),

cleaned as (

    select
        order_id,
        customer_id,
        cast(order_date  as date)      as order_date,
        lower(status)                  as status,
        cast(amount      as numeric)   as amount,
        cast(updated_at  as timestamp) as updated_at,

        -- Label orders using a custom macro
        
    case
        when amount >= 400  then 'Large'
        when amount >= 150  then 'Medium'
        else                               'Small'
    end
 as order_size

    from source

)

select * from cleaned
  );

