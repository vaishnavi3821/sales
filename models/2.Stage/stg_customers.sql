select
    customer_id,
    customer_name,
    city,
    state,
    email,
    signup_date
from {{ source('demo_sources', 'STG_CUSTOMERS') }} 