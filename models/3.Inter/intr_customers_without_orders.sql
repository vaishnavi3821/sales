{{ config(materialized='table') }}

select
    c.customer_id,
    c.customer_name,
    c.city,
    c.state,
    c.email,
    c.signup_date
from {{ ref('stg_customers') }} c
left join {{ ref('stg_orders') }} o
    on c.customer_id = o.customer_id
where o.order_id is null