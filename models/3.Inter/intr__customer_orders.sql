{{ config(materialized='table') }}

select
    c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    c.email,
    c.signup_date,

    o.order_id,
    o.product_name,
    o.order_date,
    o.quantity,
    o.amount
from {{ ref('stg_customers') }} c
inner join {{ ref('stg_orders') }} o
    on c.customer_id = o.customer_id