{{
    config(
        materialized='incremental',
        unique_key='event_id',
        tags=['marts', 'incremental']
    )
}}

with events as (

    select * from {{ ref('stg_events') }}

    {% if is_incremental() %}
        where event_ts > (
            select max(event_ts) from {{ this }}
        )
    {% endif %}

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
    left join {{ ref('dim_customers') }} c using (customer_id)

)

select * from enriched