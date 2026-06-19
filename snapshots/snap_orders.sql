{% snapshot snap_orders %}

{{
    config(
        target_schema='SNAPSHOT_SCHEMA',
        unique_key='order_id',
        strategy='check',
        check_cols=[
            'customer_id',
            'product_name',
            'order_date',
            'quantity',
            'amount'
        ],
        invalidate_hard_deletes=True
    )
}}

select
    order_id,
    customer_id,
    product_name,
    order_date,
    quantity,
    amount
from {{ source('join_practice', 'STG_ORDERS') }}

{% endsnapshot %}