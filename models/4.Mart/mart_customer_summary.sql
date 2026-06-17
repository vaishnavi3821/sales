{{ config(materialized='table') }}

select
    customer_id,
    customer_name,
    city,
    state,
    count(order_id) as total_orders,
    sum(quantity) as total_quantity,
    sum(amount) as total_amount,
    min(order_date) as first_order_date,
    max(order_date) as latest_order_date
from {{ ref('int_customer_orders') }}
group by
    customer_id,
    customer_name,
    city,
    state