with interaction_shares as (

    select
        report_version,
        report_release_date,
        max(case when interaction_type = 'directive' then pct end) as directive_pct,
        max(case when interaction_type = 'feedback_loop' then pct end) as feedback_loop_pct,
        max(case when interaction_type = 'validation' then pct end) as validation_pct,
        max(case when interaction_type = 'task_iteration' then pct end) as task_iteration_pct,
        max(case when interaction_type = 'learning' then pct end) as learning_pct
    from {{ ref('int_aei_collaboration_shares_by_version') }}
    group by 1, 2

)

select
    report_version,
    report_release_date,
    coalesce(directive_pct, 0) + coalesce(feedback_loop_pct, 0) as automation_total_pct,
    coalesce(validation_pct, 0) + coalesce(task_iteration_pct, 0) + coalesce(learning_pct, 0) as augmentation_total_pct,
    coalesce(directive_pct, 0) as directive_pct,
    coalesce(feedback_loop_pct, 0) as feedback_loop_pct,
    coalesce(validation_pct, 0) as validation_pct,
    coalesce(task_iteration_pct, 0) as task_iteration_pct,
    coalesce(learning_pct, 0) as learning_pct
from interaction_shares
order by report_release_date
