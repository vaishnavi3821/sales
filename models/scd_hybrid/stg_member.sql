{{ config(
    materialized='view',
    alias='STG_MEMBER'
) }}

SELECT
    id,

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
    last_updated,
    date_inactive,

    MD5(CONCAT_WS('|',
        COALESCE(first_name, ''),
        COALESCE(last_name, ''),
        COALESCE(email_address, ''),
        COALESCE(phone_number, '')
    )) AS scd1_hash,

    MD5(CONCAT_WS('|',
        COALESCE(memberid, ''),
        COALESCE(memberidshort, ''),
        COALESCE(employer_id, ''),
        COALESCE(clientid, ''),
        COALESCE(family_id, ''),
        COALESCE(plan_id, ''),
        COALESCE(memberrelationshipcode_id, ''),
        COALESCE(cardId, ''),
        COALESCE(altmemberid, ''),
        COALESCE(altgroupid, ''),
        COALESCE(networkprefix, '')
    )) AS scd2_hash

FROM {{ source('member_source', 'SOURCE_MEMBER') }}