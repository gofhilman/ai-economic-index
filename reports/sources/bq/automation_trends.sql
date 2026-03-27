select
    report_version,
    report_release_date,
    format_date('%B %Y', report_release_date) as report_release_label,
    automation_total_pct / 100 as automation_total_share,
    augmentation_total_pct / 100 as augmentation_total_share,
    directive_pct / 100 as directive_share,
    feedback_loop_pct / 100 as feedback_loop_share,
    validation_pct / 100 as validation_share,
    task_iteration_pct / 100 as task_iteration_share,
    learning_pct / 100 as learning_share
from `ai-economic-index.output_dataset.mart_aei_automation_trends`
order by report_release_date
