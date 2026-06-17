{{ config(materialized='view') }}

select
    order_id,
    customer_id,
    product_name,
    order_date,
    quantity,
    amount
from {{ source('join_practice', 'STG_ORDERS') }}