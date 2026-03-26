with task_pct_v1 as (

    select
        'v1' as report_version,
        {{ aei_report_release_date_literal('v1') }} as report_release_date,
        {{ aei_normalize_text('task_name') }} as task_name,
        cast(pct as float64) as pct
    from {{ ref('stg_task_pct_v1') }}

),

task_pct_v2 as (

    select
        'v2' as report_version,
        {{ aei_report_release_date_literal('v2') }} as report_release_date,
        {{ aei_normalize_text('task_name') }} as task_name,
        cast(pct as float64) as pct
    from {{ ref('stg_task_pct_v2') }}

),

task_pct_v3 as (

    select
        'v3' as report_version,
        {{ aei_report_release_date_literal('v3') }} as report_release_date,
        {{ aei_normalize_text('cluster_name') }} as task_name,
        cast(value as float64) as pct
    from {{ ref('stg_aei_raw_claude_ai_2025_08_04_to_2025_08_11') }}
    where geo_id = 'GLOBAL'
      and facet = 'onet_task'
      and variable = 'onet_task_pct'

),

task_pct_v4 as (

    select
        'v4' as report_version,
        {{ aei_report_release_date_literal('v4') }} as report_release_date,
        {{ aei_normalize_text('cluster_name') }} as task_name,
        cast(value as float64) as pct
    from {{ ref('stg_aei_raw_claude_ai_2025_11_13_to_2025_11_20') }}
    where geo_id = 'GLOBAL'
      and facet = 'onet_task'
      and variable = 'onet_task_pct'

),

unioned as (

    select * from task_pct_v1
    union all
    select * from task_pct_v2
    union all
    select * from task_pct_v3
    union all
    select * from task_pct_v4

),

aggregated as (

    select
        report_version,
        report_release_date,
        task_name,
        sum(pct) as pct
    from unioned
    group by 1, 2, 3

),

with_totals as (

    select
        *,
        sum(case when task_name != 'not_classified' then pct else 0 end) over (
            partition by report_version
        ) as pct_excluding_not_classified
    from aggregated

)

select
    report_version,
    report_release_date,
    task_name,
    case
        when report_version in ('v3', 'v4')
            then safe_divide(pct * 100, pct_excluding_not_classified)
        else pct
    end as pct
from with_totals
where not (report_version in ('v3', 'v4') and task_name = 'not_classified')
