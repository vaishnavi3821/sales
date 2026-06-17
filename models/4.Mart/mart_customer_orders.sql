{{ config(materialized='table') }}

select
    customer_id,
    customer_name,
    city,
    order_id,
    product_name,
    order_date,
    quantity,
    amount
    from {{ ref('intr_orders_without_customers') }}