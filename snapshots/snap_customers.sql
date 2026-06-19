{% snapshot snap_customers %}

{{
    config(
        target_schema='SNAPSHOT_SCHEMA',
        unique_key='customer_id',
        strategy='check',
        check_cols=[
            'customer_name',
            'city',
            'state',
            'email',
            'signup_date'
        ],
        invalidate_hard_deletes=True
    )
}}

select
    customer_id,
    customer_name,
    city,
    state,
    email,
    signup_date
from {{ source('join_practice', 'STG_CUSTOMERS') }}

{% endsnapshot %}