{% snapshot snap_orders %}

{{
    config(
        target_schema='snapshots',
        strategy='check',
        unique_key='order_id',
        check_cols=['status', 'amount'],
        invalidate_hard_deletes=false
    )
}}

select
    order_id,
    customer_id,
    order_date,
    status,
    amount,
    updated_at
from {{ ref('raw_orders') }}

{% endsnapshot %}