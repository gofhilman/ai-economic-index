select
    report_version,
    automation_total_pct,
    augmentation_total_pct,
    directive_pct,
    feedback_loop_pct,
    validation_pct,
    task_iteration_pct,
    learning_pct
from {{ ref('mart_aei_automation_trends') }}
where abs(automation_total_pct - (directive_pct + feedback_loop_pct)) > 0.001
   or abs(augmentation_total_pct - (validation_pct + task_iteration_pct + learning_pct)) > 0.001
