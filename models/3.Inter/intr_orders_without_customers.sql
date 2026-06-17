{{ config(materialized='table') }}

select
    o.order_id,
    o.customer_id,
    o.product_name,
    o.order_date,
    o.quantity,
    o.amount,
    c.customer_name,
    c.city
from {{ ref('stg_orders') }} o
left join {{ ref('stg_customers') }} c
    on o.customer_id = c.customer_id
where c.customer_id is null