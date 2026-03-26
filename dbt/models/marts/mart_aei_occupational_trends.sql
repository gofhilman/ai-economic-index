with occupational_shares as (

    select
        task_to_soc_group.soc_group,
        task_shares.report_version,
        sum(task_shares.pct) as pct
    from {{ ref('int_aei_task_shares_by_version') }} as task_shares
    inner join {{ ref('int_aei_task_to_soc_group') }} as task_to_soc_group
        on task_shares.task_name = task_to_soc_group.task_name
    group by 1, 2

),

pivoted as (

    select
        soc_group,
        sum(case when report_version = 'v1' then pct else 0 end) as v1_pct,
        sum(case when report_version = 'v2' then pct else 0 end) as v2_pct,
        sum(case when report_version = 'v3' then pct else 0 end) as v3_pct,
        sum(case when report_version = 'v4' then pct else 0 end) as v4_pct
    from occupational_shares
    group by 1

)

select
    soc_group,
    v1_pct,
    v2_pct,
    v3_pct,
    v4_pct,
    v4_pct - v1_pct as latest_vs_v1_diff_pp
from pivoted
where greatest(v1_pct, v2_pct, v3_pct, v4_pct) >= 1.0
