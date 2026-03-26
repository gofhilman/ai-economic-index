with collaboration_v1 as (

    select
        'v1' as report_version,
        {{ aei_report_release_date_literal('v1') }} as report_release_date,
        {{ aei_normalize_identifier('interaction_type') }} as interaction_type,
        cast(pct as float64) as pct
    from {{ ref('stg_automation_vs_augmentation_v1') }}

),

collaboration_v2 as (

    select
        'v2' as report_version,
        {{ aei_report_release_date_literal('v2') }} as report_release_date,
        {{ aei_normalize_identifier('interaction_type') }} as interaction_type,
        cast(pct as float64) as pct
    from {{ ref('stg_automation_vs_augmentation_v2') }}

),

collaboration_v3 as (

    select
        'v3' as report_version,
        {{ aei_report_release_date_literal('v3') }} as report_release_date,
        {{ aei_normalize_identifier('cluster_name') }} as interaction_type,
        cast(value as float64) as pct
    from {{ ref('stg_aei_raw_claude_ai_2025_08_04_to_2025_08_11') }}
    where geo_id = 'GLOBAL'
      and facet = 'collaboration'
      and level = 0
      and variable = 'collaboration_pct'

),

collaboration_v4 as (

    select
        'v4' as report_version,
        {{ aei_report_release_date_literal('v4') }} as report_release_date,
        {{ aei_normalize_identifier('cluster_name') }} as interaction_type,
        cast(value as float64) as pct
    from {{ ref('stg_aei_raw_claude_ai_2025_11_13_to_2025_11_20') }}
    where geo_id = 'GLOBAL'
      and facet = 'collaboration'
      and level = 0
      and variable = 'collaboration_pct'

),

unioned as (

    select * from collaboration_v1
    union all
    select * from collaboration_v2
    union all
    select * from collaboration_v3
    union all
    select * from collaboration_v4

),

aggregated as (

    select
        report_version,
        report_release_date,
        interaction_type,
        sum(pct) as pct
    from unioned
    group by 1, 2, 3

),

with_totals as (

    select
        *,
        sum(pct) over (partition by report_version) as pct_total,
        sum(case when interaction_type != 'not_classified' then pct else 0 end) over (
            partition by report_version
        ) as pct_excluding_not_classified
    from aggregated

)

select
    report_version,
    report_release_date,
    interaction_type,
    case
        when report_version in ('v1', 'v2')
            then safe_divide(pct * 100, pct_total)
        else safe_divide(pct * 100, pct_excluding_not_classified)
    end as pct
from with_totals
where not (report_version in ('v3', 'v4') and interaction_type = 'not_classified')
