{{ config(
    materialized='incremental',
    unique_key='dbt_unique_key',
    incremental_strategy='delete+insert'
) }}

with src as (

    select
        id as source_person_key,
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

        md5(concat_ws('|',
            coalesce(memberid, ''),
            coalesce(memberidshort, ''),
            coalesce(employer_id, ''),
            coalesce(clientid, ''),
            coalesce(family_id, ''),
            coalesce(plan_id, ''),
            coalesce(memberrelationshipcode_id, ''),
            coalesce(cardId, ''),
            coalesce(altmemberid, ''),
            coalesce(altgroupid, ''),
            coalesce(networkprefix, '')
        )) as scd2_hash,

        md5(concat_ws('|',
            coalesce(first_name, ''),
            coalesce(last_name, ''),
            coalesce(email_address, ''),
            coalesce(phone_number, ''),
            coalesce(to_varchar(isactive), '')
        )) as scd1_hash

    from {{ source('member_db', 'MEMBER_SOURCE') }}
    where id is not null

),

active_target as (

    {% if is_incremental() %}
        select *
        from {{ this }}
        where active_status = 1
    {% else %}
        select
            null as unique_id,
            null as source_person_key,
            null as scd1_hash,
            null as scd2_hash,
            null as isactive,
            null as row_created_date,
            null as dbt_unique_key
        where 1 = 0
    {% endif %}

),

max_key as (

    {% if is_incremental() %}
        select coalesce(max(unique_id), 0) as max_unique_id
        from {{ this }}
    {% else %}
        select 0 as max_unique_id
    {% endif %}

),

classified as (

    select
        s.*,
        t.unique_id as old_unique_id,
        t.scd1_hash as old_scd1_hash,
        t.scd2_hash as old_scd2_hash,
        t.isactive as old_isactive,
        t.row_created_date as old_row_created_date,
        t.dbt_unique_key as old_dbt_unique_key,

        case
            when t.source_person_key is null then 'NEW'
            when s.isactive = 1 and coalesce(t.isactive, 0) = 0 and s.scd2_hash <> t.scd2_hash then 'REACTIVATE_SCD2'
            when s.isactive = 1 and coalesce(t.isactive, 0) = 0 then 'REACTIVATE_SCD1'
            when s.scd2_hash <> t.scd2_hash then 'SCD2_CHANGE'
            when s.scd1_hash <> t.scd1_hash then 'SCD1_CHANGE'
            else 'NO_CHANGE'
        end as change_type

    from src s
    left join active_target t
        on s.source_person_key = t.source_person_key

),

numbered as (

    select
        *,
        sum(
            case
                when change_type in ('NEW', 'SCD2_CHANGE', 'REACTIVATE_SCD2') then 1
                else 0
            end
        ) over (
            order by source_person_key
            rows between unbounded preceding and current row
        ) as new_version_seq
    from classified
    where change_type <> 'NO_CHANGE'

),

expire_old_scd2 as (

    {% if is_incremental() %}

        select
            old.unique_id,
            old.source_person_key,
            old.memberid,
            old.memberidshort,
            old.employer_id,
            old.clientid,
            old.family_id,
            old.plan_id,
            old.memberrelationshipcode_id,
            old.cardId,
            old.altmemberid,
            old.altgroupid,
            old.networkprefix,
            old.first_name,
            old.last_name,
            old.email_address,
            old.phone_number,
            old.isactive,
            old.last_updated,
            old.row_created_date,
            current_date() as row_modified_date,
            current_date() as date_inactive,
            0 as active_status,
            old.scd1_hash,
            old.scd2_hash,
            old.dbt_unique_key

        from numbered n
        join {{ this }} old
            on n.old_unique_id = old.unique_id
        where n.change_type in ('SCD2_CHANGE', 'REACTIVATE_SCD2')
          and old.active_status = 1

    {% else %}

        select
            null as unique_id,
            null as source_person_key,
            null as memberid,
            null as memberidshort,
            null as employer_id,
            null as clientid,
            null as family_id,
            null as plan_id,
            null as memberrelationshipcode_id,
            null as cardId,
            null as altmemberid,
            null as altgroupid,
            null as networkprefix,
            null as first_name,
            null as last_name,
            null as email_address,
            null as phone_number,
            null as isactive,
            null as last_updated,
            null as row_created_date,
            null as row_modified_date,
            null as date_inactive,
            null as active_status,
            null as scd1_hash,
            null as scd2_hash,
            null as dbt_unique_key
        where 1 = 0

    {% endif %}

),

insert_or_update as (

    select
        case
            when change_type in ('NEW', 'SCD2_CHANGE', 'REACTIVATE_SCD2')
                then (select max_unique_id from max_key) + new_version_seq
            else old_unique_id
        end as unique_id,

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

        current_date() as last_updated,

        case
            when change_type in ('NEW', 'SCD2_CHANGE', 'REACTIVATE_SCD2')
                then current_date()
            else old_row_created_date
        end as row_created_date,

        current_date() as row_modified_date,

        case
            when isactive = 0 then current_date()
            else null
        end as date_inactive,

        case
            when isactive = 1 then 1
            else 0
        end as active_status,

        scd1_hash,
        scd2_hash,

        case
            when change_type in ('NEW', 'SCD2_CHANGE', 'REACTIVATE_SCD2')
                then concat(source_person_key, '_', (select max_unique_id from max_key) + new_version_seq)
            else old_dbt_unique_key
        end as dbt_unique_key

    from numbered

)

select * from expire_old_scd2

union all

select * from insert_or_update