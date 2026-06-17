{{ config(materialized='view') }}

select
    customer_id,
    customer_name,
    city,
    state,
    email,
    signup_date
from {{ source('join_practice', 'STG_CUSTOMERS') }}