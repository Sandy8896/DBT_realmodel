
      
  
    

create or replace transient table DBT_TEST.snapshots.snap_customers
    
    
    
    as (
    

    select *,
        md5(coalesce(cast(customer_id as varchar ), '')
         || '|' || coalesce(cast(updated_at as varchar ), '')
        ) as dbt_scd_id,
        updated_at as dbt_updated_at,
        updated_at as dbt_valid_from,
        
  
  coalesce(nullif(updated_at, updated_at), null)
  as dbt_valid_to
from (
        



select
    customer_id,
    first_name,
    last_name,
    email,
    country,
    signup_date,
    updated_at
from DBT_TEST.raw.raw_customers

    ) sbq



    )
;


  
  