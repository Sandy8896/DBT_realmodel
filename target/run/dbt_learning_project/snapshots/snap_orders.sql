
      
  
    

create or replace transient table DBT_TEST.snapshots.snap_orders
    
    
    
    as (
    

    select *,
        md5(coalesce(cast(order_id as varchar ), '')
         || '|' || coalesce(cast(updated_at as varchar ), '')
        ) as dbt_scd_id,
        updated_at as dbt_updated_at,
        updated_at as dbt_valid_from,
        
  
  coalesce(nullif(updated_at, updated_at), null)
  as dbt_valid_to
from (
        



select
    order_id,
    customer_id,
    order_date,
    status,
    amount,
    updated_at
from DBT_TEST.raw.raw_orders

    ) sbq



    )
;


  
  