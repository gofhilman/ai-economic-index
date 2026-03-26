with expected as (

    select
        'int_aei_task_shares_by_version' as model_name,
        'v1' as report_version,
        date '2025-02-10' as report_release_date
    union all
    select
        'int_aei_task_shares_by_version' as model_name,
        'v2' as report_version,
        date '2025-03-27' as report_release_date
    union all
    select
        'int_aei_task_shares_by_version' as model_name,
        'v3' as report_version,
        date '2025-09-15' as report_release_date
    union all
    select
        'int_aei_task_shares_by_version' as model_name,
        'v4' as report_version,
        date '2026-01-15' as report_release_date
    union all
    select
        'int_aei_task_shares_by_version' as model_name,
        'v5' as report_version,
        date '2026-03-24' as report_release_date
    union all
    select
        'int_aei_collaboration_shares_by_version' as model_name,
        'v1' as report_version,
        date '2025-02-10' as report_release_date
    union all
    select
        'int_aei_collaboration_shares_by_version' as model_name,
        'v2' as report_version,
        date '2025-03-27' as report_release_date
    union all
    select
        'int_aei_collaboration_shares_by_version' as model_name,
        'v3' as report_version,
        date '2025-09-15' as report_release_date
    union all
    select
        'int_aei_collaboration_shares_by_version' as model_name,
        'v4' as report_version,
        date '2026-01-15' as report_release_date
    union all
    select
        'int_aei_collaboration_shares_by_version' as model_name,
        'v5' as report_version,
        date '2026-03-24' as report_release_date

),

actual as (

    select distinct
        'int_aei_task_shares_by_version' as model_name,
        report_version,
        report_release_date
    from {{ ref('int_aei_task_shares_by_version') }}

    union distinct

    select distinct
        'int_aei_collaboration_shares_by_version' as model_name,
        report_version,
        report_release_date
    from {{ ref('int_aei_collaboration_shares_by_version') }}

),

unexpected_rows as (

    (
        select * from actual
        except distinct
        select * from expected
    )

    union all

    (
        select * from expected
        except distinct
        select * from actual
    )

)

select *
from unexpected_rows
