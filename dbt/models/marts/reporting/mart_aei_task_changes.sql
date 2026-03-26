with task_shares as (

    select
        task_name,
        {{ aei_version_pct_columns('report_version', 'pct') }}
    from {{ ref('int_aei_task_shares_by_version') }}
    group by 1

),

with_context as (

    select
        task_shares.task_name,
        task_to_soc_group.soc_group,
        task_shares.v1_pct,
        task_shares.v2_pct,
        task_shares.v3_pct,
        task_shares.v4_pct
    from task_shares
    left join {{ ref('int_aei_task_to_soc_group') }} as task_to_soc_group
        on task_shares.task_name = task_to_soc_group.task_name

),

calculated as (

    select
        task_name,
        soc_group,
        v1_pct,
        v2_pct,
        v3_pct,
        v4_pct,
        v4_pct - v1_pct as latest_vs_v1_diff_pp,
        case
            when v1_pct > 0
                then safe_divide((v4_pct - v1_pct) * 100, v1_pct)
        end as latest_vs_v1_rel_change_pct,
        v1_pct = 0 as is_new_since_v1,
        case
            when v1_pct = 0 then 'new'
            else format('%+.0f%%', safe_divide((v4_pct - v1_pct) * 100, v1_pct))
        end as change_label
    from with_context

)

select
    task_name,
    soc_group,
    v1_pct,
    v2_pct,
    v3_pct,
    v4_pct,
    latest_vs_v1_diff_pp,
    latest_vs_v1_rel_change_pct,
    is_new_since_v1,
    change_label
from calculated
where abs(latest_vs_v1_diff_pp) >= 0.2
