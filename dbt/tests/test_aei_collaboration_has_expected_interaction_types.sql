with versions as (

    select 'v1' as report_version
    union all
    select 'v2' as report_version
    union all
    select 'v3' as report_version
    union all
    select 'v4' as report_version
    union all
    select 'v5' as report_version

),

interactions as (

    select 'directive' as interaction_type
    union all
    select 'feedback_loop' as interaction_type
    union all
    select 'validation' as interaction_type
    union all
    select 'task_iteration' as interaction_type
    union all
    select 'learning' as interaction_type

),

expected as (

    select
        versions.report_version,
        interactions.interaction_type
    from versions
    cross join interactions

),

actual as (

    select distinct
        report_version,
        interaction_type
    from {{ ref('int_aei_collaboration_shares_by_version') }}
    where interaction_type in (
        'directive',
        'feedback_loop',
        'validation',
        'task_iteration',
        'learning'
    )

)

select
    expected.report_version,
    expected.interaction_type
from expected
left join actual
    on expected.report_version = actual.report_version
   and expected.interaction_type = actual.interaction_type
where actual.report_version is null
