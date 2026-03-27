with base as (

    select
        report_version,
        report_release_date,
        format_date('%B %Y', report_release_date) as report_release_label,
        interaction_pattern.interaction_key,
        interaction_pattern.interaction_label,
        interaction_pattern.interaction_family,
        interaction_pattern.share
    from `ai-economic-index.output_dataset.mart_aei_automation_trends`,
    unnest([
        struct(
            'directive' as interaction_key,
            'Directive' as interaction_label,
            'automation' as interaction_family,
            directive_pct / 100 as share
        ),
        struct(
            'feedback_loop' as interaction_key,
            'Feedback Loop' as interaction_label,
            'automation' as interaction_family,
            feedback_loop_pct / 100 as share
        ),
        struct(
            'validation' as interaction_key,
            'Validation' as interaction_label,
            'augmentation' as interaction_family,
            validation_pct / 100 as share
        ),
        struct(
            'task_iteration' as interaction_key,
            'Task Iteration' as interaction_label,
            'augmentation' as interaction_family,
            task_iteration_pct / 100 as share
        ),
        struct(
            'learning' as interaction_key,
            'Learning' as interaction_label,
            'augmentation' as interaction_family,
            learning_pct / 100 as share
        )
    ]) as interaction_pattern

)

select
    report_version,
    report_release_date,
    report_release_label,
    interaction_key,
    interaction_label,
    interaction_family,
    'all' as interaction_filter_group,
    share
from base

union all

select
    report_version,
    report_release_date,
    report_release_label,
    interaction_key,
    interaction_label,
    interaction_family,
    interaction_family as interaction_filter_group,
    share
from base
