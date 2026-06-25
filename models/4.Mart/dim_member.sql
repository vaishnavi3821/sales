{{ config(materialized='table') }}

select
    unique_id,
    source_person_key,
    memberid,
    memberidshort,
    employer_id,
    clientid,
    family_id,
    plan_id,
    memberrelationshipcode_id,
    cardId,
    altmemberid,
    altgroupid,
    networkprefix,
    first_name,
    last_name,
    email_address,
    phone_number,
    isactive,
    active_status,
    last_updated,
    row_created_date,
    row_modified_date,
    date_inactive
from {{ ref('intr_member') }}