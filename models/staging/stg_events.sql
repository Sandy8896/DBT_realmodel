-- ============================================================
-- MATERIALIZATION: VIEW
-- ============================================================

{{
  config(
    materialized = 'view',
    tags         = ['staging', 'events']
  )
}}

with source as (

    select * from {{ ref('raw_events') }}

),

parsed as (

    select
        event_id,
        customer_id,
        lower(event_type)               as event_type,
        cast(event_ts   as timestamp)   as event_ts,
        page,
        cast(updated_at as timestamp)   as updated_at,
        -- Extract date part for partitioning in incremental model
        cast(event_ts   as date)        as event_date

    from source

)

select * from parsed
