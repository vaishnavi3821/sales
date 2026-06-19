{{ config(materialized='table') }}

with customer_orders as (

    select
        customer_id,
        customer_name,
        city,
        state,
        email,
        signup_date,
        order_id,
        product_name,
        order_date,
        quantity,
        amount,
        'CUSTOMER_WITH_ORDER' as record_type
    from {{ ref('intr_customer_orders') }}

),

customers_without_orders as (

    select
        customer_id,
        customer_name,
        city,
        state,
        email,
        signup_date,
        null::number as order_id,
        null::varchar as product_name,
        null::date as order_date,
        null::number as quantity,
        null::number(10,2) as amount,
        'CUSTOMER_WITHOUT_ORDER' as record_type
    from {{ ref('intr_customers_without_orders') }}

),

orders_without_customers as (

    select
        customer_id,
        customer_name,
        city,
        null::varchar as state,
        null::varchar as email,
        null::date as signup_date,
        order_id,
        product_name,
        order_date,
        quantity,
        amount,
        'ORDER_WITHOUT_CUSTOMER' as record_type
    from {{ ref('intr_orders_without_customers') }}

)

select *
from customer_orders

union all

select *
from customers_without_orders

union all

select *
from orders_without_customers