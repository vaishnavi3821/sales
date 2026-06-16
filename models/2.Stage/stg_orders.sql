select
    order_id,
    customer_id,
    product_name,
    order_date,
    quantity,
    amount
from {{ source('demo_sources', 'STG_ORDERS') }}