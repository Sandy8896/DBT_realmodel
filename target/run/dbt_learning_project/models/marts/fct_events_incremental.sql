
  
    

create or replace transient table DBT_TEST.marts.fct_events_incremental
    
    
    
    as (

with events as (

    select * from DBT_TEST.staging.stg_events

    

),

enriched as (

    select
        e.event_id,
        e.customer_id,
        e.event_type,
        e.event_ts,
        e.event_date,
        e.page,
        c.country,
        c.segment as customer_segment,
        current_timestamp() as dbt_loaded_at

    from events e
    left join DBT_TEST.marts.dim_customers c using (customer_id)

)

select * from enriched
    )
;


  