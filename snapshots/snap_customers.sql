{% snapshot snap_customers %}

{{
    config(
        target_schema='snapshots',
        strategy='timestamp',
        unique_key='customer_id',
        updated_at='updated_at',
        invalidate_hard_deletes=true
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    country,
    signup_date,
    updated_at
from {{ ref('raw_customers') }}

{% endsnapshot %}
