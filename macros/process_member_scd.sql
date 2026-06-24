{% macro process_member_scd() %}

{% set scd1_update_sql %}

UPDATE MEMBER_DB.PUBLIC.DIM_MEMBER tgt
SET
    first_name = src.first_name,
    last_name = src.last_name,
    email_address = src.email_address,
    phone_number = src.phone_number,
    isactive = 1,
    date_inactive = NULL,
    last_updated = CURRENT_DATE()
FROM {{ ref('stg_member') }} src
WHERE tgt.id = src.id
  AND tgt.isactive = 1

  -- SCD2 columns should be same
  AND MD5(CONCAT_WS('|',
        COALESCE(tgt.memberid, ''),
        COALESCE(tgt.memberidshort, ''),
        COALESCE(tgt.employer_id, ''),
        COALESCE(tgt.clientid, ''),
        COALESCE(tgt.family_id, ''),
        COALESCE(tgt.plan_id, ''),
        COALESCE(tgt.memberrelationshipcode_id, ''),
        COALESCE(tgt.cardId, ''),
        COALESCE(tgt.altmemberid, ''),
        COALESCE(tgt.altgroupid, ''),
        COALESCE(tgt.networkprefix, '')
      )) = src.scd2_hash

  -- SCD1 columns changed
  AND MD5(CONCAT_WS('|',
        COALESCE(tgt.first_name, ''),
        COALESCE(tgt.last_name, ''),
        COALESCE(tgt.email_address, ''),
        COALESCE(tgt.phone_number, '')
      )) <> src.scd1_hash;

{% endset %}

{% do run_query(scd1_update_sql) %}


{% set scd2_expire_sql %}

UPDATE MEMBER_DB.PUBLIC.DIM_MEMBER tgt
SET
    isactive = 0,
    date_inactive = CURRENT_DATE(),
    last_updated = CURRENT_DATE()
FROM {{ ref('stg_member') }} src
WHERE tgt.id = src.id
  AND tgt.isactive = 1
  AND src.isactive = 1
  AND MD5(CONCAT_WS('|',
        COALESCE(tgt.memberid, ''),
        COALESCE(tgt.memberidshort, ''),
        COALESCE(tgt.employer_id, ''),
        COALESCE(tgt.clientid, ''),
        COALESCE(tgt.family_id, ''),
        COALESCE(tgt.plan_id, ''),
        COALESCE(tgt.memberrelationshipcode_id, ''),
        COALESCE(tgt.cardId, ''),
        COALESCE(tgt.altmemberid, ''),
        COALESCE(tgt.altgroupid, ''),
        COALESCE(tgt.networkprefix, '')
      )) <> src.scd2_hash;

{% endset %}

{% do run_query(scd2_expire_sql) %}


{% set insert_new_sql %}

INSERT INTO MEMBER_DB.PUBLIC.DIM_MEMBER (
    unique_id,
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
    date_inactive
)
SELECT
    MEMBER_DB.PUBLIC.MEMBER_SEQ.NEXTVAL,
    src.id,
    src.memberid,
    src.memberidshort,
    src.employer_id,
    src.clientid,
    src.family_id,
    src.plan_id,
    src.memberrelationshipcode_id,
    src.cardId,
    src.altmemberid,
    src.altgroupid,
    src.networkprefix,
    src.first_name,
    src.last_name,
    src.email_address,
    src.phone_number,
    1,
    CURRENT_DATE(),
    NULL
FROM {{ ref('stg_member') }} src
WHERE src.isactive = 1
  AND NOT EXISTS (
      SELECT 1
      FROM MEMBER_DB.PUBLIC.DIM_MEMBER tgt
      WHERE tgt.id = src.id
        AND tgt.isactive = 1
  );

{% endset %}

{% do run_query(insert_new_sql) %}


{% set reactivate_sql %}

UPDATE MEMBER_DB.PUBLIC.DIM_MEMBER tgt
SET
    isactive = 1,
    date_inactive = NULL,
    last_updated = CURRENT_DATE(),
    first_name = src.first_name,
    last_name = src.last_name,
    email_address = src.email_address,
    phone_number = src.phone_number
FROM {{ ref('stg_member') }} src
WHERE tgt.id = src.id
  AND tgt.isactive = 0
  AND src.isactive = 1
  AND NOT EXISTS (
      SELECT 1
      FROM MEMBER_DB.PUBLIC.DIM_MEMBER active_tgt
      WHERE active_tgt.id = src.id
        AND active_tgt.isactive = 1
  )
  AND MD5(CONCAT_WS('|',
        COALESCE(tgt.memberid, ''),
        COALESCE(tgt.memberidshort, ''),
        COALESCE(tgt.employer_id, ''),
        COALESCE(tgt.clientid, ''),
        COALESCE(tgt.family_id, ''),
        COALESCE(tgt.plan_id, ''),
        COALESCE(tgt.memberrelationshipcode_id, ''),
        COALESCE(tgt.cardId, ''),
        COALESCE(tgt.altmemberid, ''),
        COALESCE(tgt.altgroupid, ''),
        COALESCE(tgt.networkprefix, '')
      )) = src.scd2_hash;

{% endset %}

{% do run_query(reactivate_sql) %}

{% endmacro %}