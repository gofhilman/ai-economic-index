with base as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        facet,
        variable,
        cluster_name,
        value
    from {{ ref('mart_aei_enriched_claude_ai_2026_02_05_to_2026_02_12') }}
    where geo_id = 'GLOBAL'

),

task_to_soc as (

    select distinct
        task_name,
        replace(replace(soc_group, ' Occupations', ''), ' Occupation', '') as soc_group
    from {{ ref('int_aei_task_to_soc_group') }}

),

task_use_case_counts as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        {{ aei_normalize_text("split(cluster_name, '::')[safe_offset(0)]") }} as task_name,
        lower(split(cluster_name, '::')[safe_offset(1)]) as use_case_name,
        value as use_case_count
    from base
    where facet = 'onet_task::use_case'
      and variable = 'onet_task_use_case_count'

),

task_work_weights as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        task_name,
        sum(case when use_case_name = 'work' then use_case_count else 0 end) as work_use_case_count,
        sum(use_case_count) as total_use_case_count,
        safe_divide(
            sum(case when use_case_name = 'work' then use_case_count else 0 end),
            sum(use_case_count)
        ) as work_share
    from task_use_case_counts
    group by 1, 2, 3, 4, 5, 6, 7
    having work_use_case_count > 0

),

task_success_metrics as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        {{ aei_normalize_text("split(cluster_name, '::')[safe_offset(0)]") }} as task_name,
        sum(
            case
                when lower(split(cluster_name, '::')[safe_offset(1)]) = 'yes' then value
                else 0
            end
        ) as success_yes_count,
        sum(
            case
                when lower(split(cluster_name, '::')[safe_offset(1)]) = 'no' then value
                else 0
            end
        ) as success_no_count,
        sum(
            case
                when lower(split(cluster_name, '::')[safe_offset(1)]) not in ('yes', 'no') then value
                else 0
            end
        ) as success_unknown_count
    from base
    where facet = 'onet_task::task_success'
      and variable = 'onet_task_task_success_count'
    group by 1, 2, 3, 4, 5, 6, 7

),

task_human_only_ability_metrics as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        {{ aei_normalize_text("split(cluster_name, '::')[safe_offset(0)]") }} as task_name,
        sum(
            case
                when lower(split(cluster_name, '::')[safe_offset(1)]) = 'no' then value
                else 0
            end
        ) as requires_ai_count,
        sum(
            case
                when lower(split(cluster_name, '::')[safe_offset(1)]) = 'yes' then value
                else 0
            end
        ) as human_only_possible_count,
        sum(
            case
                when lower(split(cluster_name, '::')[safe_offset(1)]) not in ('yes', 'no') then value
                else 0
            end
        ) as human_only_unknown_count
    from base
    where facet = 'onet_task::human_only_ability'
      and variable = 'onet_task_human_only_ability_count'
    group by 1, 2, 3, 4, 5, 6, 7

),

task_ai_autonomy_metrics as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        {{ aei_normalize_text("split(cluster_name, '::')[safe_offset(0)]") }} as task_name,
        max(case when variable = 'onet_task_ai_autonomy_count' then value end) as ai_autonomy_count,
        max(case when variable = 'onet_task_ai_autonomy_mean' then value end) as ai_autonomy_mean,
        max(case when variable = 'onet_task_ai_autonomy_mean_ci_lower' then value end) as ai_autonomy_mean_ci_lower,
        max(case when variable = 'onet_task_ai_autonomy_mean_ci_upper' then value end) as ai_autonomy_mean_ci_upper
    from base
    where facet = 'onet_task::ai_autonomy'
      and variable in (
          'onet_task_ai_autonomy_count',
          'onet_task_ai_autonomy_mean',
          'onet_task_ai_autonomy_mean_ci_lower',
          'onet_task_ai_autonomy_mean_ci_upper'
      )
    group by 1, 2, 3, 4, 5, 6, 7

),

task_human_only_time_metrics as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        {{ aei_normalize_text("split(cluster_name, '::')[safe_offset(0)]") }} as task_name,
        max(case when variable = 'onet_task_human_only_time_count' then value end) as human_only_time_count,
        max(case when variable = 'onet_task_human_only_time_mean' then value end) as human_only_time_mean,
        max(case when variable = 'onet_task_human_only_time_mean_ci_lower' then value end) as human_only_time_mean_ci_lower,
        max(case when variable = 'onet_task_human_only_time_mean_ci_upper' then value end) as human_only_time_mean_ci_upper
    from base
    where facet = 'onet_task::human_only_time'
      and variable in (
          'onet_task_human_only_time_count',
          'onet_task_human_only_time_mean',
          'onet_task_human_only_time_mean_ci_lower',
          'onet_task_human_only_time_mean_ci_upper'
      )
    group by 1, 2, 3, 4, 5, 6, 7

),

task_human_with_ai_time_metrics as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        {{ aei_normalize_text("split(cluster_name, '::')[safe_offset(0)]") }} as task_name,
        max(case when variable = 'onet_task_human_with_ai_time_count' then value end) as human_with_ai_time_count,
        max(case when variable = 'onet_task_human_with_ai_time_mean' then value end) as human_with_ai_time_mean,
        max(case when variable = 'onet_task_human_with_ai_time_mean_ci_lower' then value end) as human_with_ai_time_mean_ci_lower,
        max(case when variable = 'onet_task_human_with_ai_time_mean_ci_upper' then value end) as human_with_ai_time_mean_ci_upper
    from base
    where facet = 'onet_task::human_with_ai_time'
      and variable in (
          'onet_task_human_with_ai_time_count',
          'onet_task_human_with_ai_time_mean',
          'onet_task_human_with_ai_time_mean_ci_lower',
          'onet_task_human_with_ai_time_mean_ci_upper'
      )
    group by 1, 2, 3, 4, 5, 6, 7

),

soc_rollup_inputs as (

    -- The source mart exposes work as a task intersection, while the requested
    -- outcomes are task-level. Reweighting by each task's work share provides a
    -- work-only approximation before rolling up to SOC groups.
    select
        task_work_weights.geo_id,
        task_work_weights.geo_name,
        task_work_weights.geography,
        task_work_weights.date_start,
        task_work_weights.date_end,
        task_work_weights.platform_and_product,
        'work' as use_case,
        task_to_soc.soc_group,
        task_work_weights.task_name,
        task_work_weights.work_use_case_count,
        task_work_weights.total_use_case_count,
        task_work_weights.work_share,
        task_work_weights.work_share * coalesce(task_success_metrics.success_yes_count, 0) as estimated_success_yes_work_count,
        task_work_weights.work_share * (
            coalesce(task_success_metrics.success_yes_count, 0)
            + coalesce(task_success_metrics.success_no_count, 0)
        ) as estimated_task_success_work_count,
        task_work_weights.work_share * coalesce(task_human_only_ability_metrics.requires_ai_count, 0) as estimated_requires_ai_work_count,
        task_work_weights.work_share * (
            coalesce(task_human_only_ability_metrics.requires_ai_count, 0)
            + coalesce(task_human_only_ability_metrics.human_only_possible_count, 0)
        ) as estimated_human_only_ability_work_count,
        task_work_weights.work_share * coalesce(task_ai_autonomy_metrics.ai_autonomy_count, 0) as estimated_ai_autonomy_work_count,
        coalesce(task_ai_autonomy_metrics.ai_autonomy_mean, 0) as ai_autonomy_mean,
        coalesce(task_ai_autonomy_metrics.ai_autonomy_mean_ci_lower, 0) as ai_autonomy_mean_ci_lower,
        coalesce(task_ai_autonomy_metrics.ai_autonomy_mean_ci_upper, 0) as ai_autonomy_mean_ci_upper,
        task_work_weights.work_share * coalesce(task_human_only_time_metrics.human_only_time_count, 0) as estimated_human_only_time_work_count,
        coalesce(task_human_only_time_metrics.human_only_time_mean, 0) as human_only_time_mean,
        coalesce(task_human_only_time_metrics.human_only_time_mean_ci_lower, 0) as human_only_time_mean_ci_lower,
        coalesce(task_human_only_time_metrics.human_only_time_mean_ci_upper, 0) as human_only_time_mean_ci_upper,
        task_work_weights.work_share * coalesce(task_human_with_ai_time_metrics.human_with_ai_time_count, 0) as estimated_human_with_ai_time_work_count,
        coalesce(task_human_with_ai_time_metrics.human_with_ai_time_mean, 0) as human_with_ai_time_mean,
        coalesce(task_human_with_ai_time_metrics.human_with_ai_time_mean_ci_lower, 0) as human_with_ai_time_mean_ci_lower,
        coalesce(task_human_with_ai_time_metrics.human_with_ai_time_mean_ci_upper, 0) as human_with_ai_time_mean_ci_upper
    from task_work_weights
    inner join task_to_soc
        on task_work_weights.task_name = task_to_soc.task_name
    left join task_success_metrics
        on task_work_weights.geo_id = task_success_metrics.geo_id
       and task_work_weights.date_start = task_success_metrics.date_start
       and task_work_weights.date_end = task_success_metrics.date_end
       and task_work_weights.platform_and_product = task_success_metrics.platform_and_product
       and task_work_weights.task_name = task_success_metrics.task_name
    left join task_human_only_ability_metrics
        on task_work_weights.geo_id = task_human_only_ability_metrics.geo_id
       and task_work_weights.date_start = task_human_only_ability_metrics.date_start
       and task_work_weights.date_end = task_human_only_ability_metrics.date_end
       and task_work_weights.platform_and_product = task_human_only_ability_metrics.platform_and_product
       and task_work_weights.task_name = task_human_only_ability_metrics.task_name
    left join task_ai_autonomy_metrics
        on task_work_weights.geo_id = task_ai_autonomy_metrics.geo_id
       and task_work_weights.date_start = task_ai_autonomy_metrics.date_start
       and task_work_weights.date_end = task_ai_autonomy_metrics.date_end
       and task_work_weights.platform_and_product = task_ai_autonomy_metrics.platform_and_product
       and task_work_weights.task_name = task_ai_autonomy_metrics.task_name
    left join task_human_only_time_metrics
        on task_work_weights.geo_id = task_human_only_time_metrics.geo_id
       and task_work_weights.date_start = task_human_only_time_metrics.date_start
       and task_work_weights.date_end = task_human_only_time_metrics.date_end
       and task_work_weights.platform_and_product = task_human_only_time_metrics.platform_and_product
       and task_work_weights.task_name = task_human_only_time_metrics.task_name
    left join task_human_with_ai_time_metrics
        on task_work_weights.geo_id = task_human_with_ai_time_metrics.geo_id
       and task_work_weights.date_start = task_human_with_ai_time_metrics.date_start
       and task_work_weights.date_end = task_human_with_ai_time_metrics.date_end
       and task_work_weights.platform_and_product = task_human_with_ai_time_metrics.platform_and_product
       and task_work_weights.task_name = task_human_with_ai_time_metrics.task_name

),

soc_aggregates as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        use_case,
        soc_group,
        count(distinct task_name) as mapped_task_count,
        sum(work_use_case_count) as work_use_case_count,
        sum(estimated_task_success_work_count) as task_success_observation_count,
        sum(estimated_success_yes_work_count) as successful_task_count,
        sum(estimated_human_only_ability_work_count) as human_only_ability_observation_count,
        sum(estimated_requires_ai_work_count) as requires_ai_task_count,
        sum(estimated_ai_autonomy_work_count) as ai_autonomy_observation_count,
        sum(ai_autonomy_mean * estimated_ai_autonomy_work_count) as ai_autonomy_weighted_sum,
        sum(ai_autonomy_mean_ci_lower * estimated_ai_autonomy_work_count) as ai_autonomy_ci_lower_weighted_sum,
        sum(ai_autonomy_mean_ci_upper * estimated_ai_autonomy_work_count) as ai_autonomy_ci_upper_weighted_sum,
        sum(estimated_human_only_time_work_count) as human_only_time_observation_count,
        sum(human_only_time_mean * estimated_human_only_time_work_count) as human_only_time_weighted_sum,
        sum(human_only_time_mean_ci_lower * estimated_human_only_time_work_count) as human_only_time_ci_lower_weighted_sum,
        sum(human_only_time_mean_ci_upper * estimated_human_only_time_work_count) as human_only_time_ci_upper_weighted_sum,
        sum(estimated_human_with_ai_time_work_count) as human_with_ai_time_observation_count,
        sum(human_with_ai_time_mean * estimated_human_with_ai_time_work_count) as human_with_ai_time_weighted_sum,
        sum(human_with_ai_time_mean_ci_lower * estimated_human_with_ai_time_work_count) as human_with_ai_time_ci_lower_weighted_sum,
        sum(human_with_ai_time_mean_ci_upper * estimated_human_with_ai_time_work_count) as human_with_ai_time_ci_upper_weighted_sum
    from soc_rollup_inputs
    group by 1, 2, 3, 4, 5, 6, 7, 8

),

final as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        use_case,
        soc_group,
        mapped_task_count,
        work_use_case_count,
        safe_divide(
            work_use_case_count * 100,
            sum(work_use_case_count) over (
                partition by geo_id, date_start, date_end, platform_and_product, use_case
            )
        ) as work_use_case_pct,
        task_success_observation_count,
        successful_task_count,
        safe_divide(successful_task_count, task_success_observation_count) as task_success_rate,
        ai_autonomy_observation_count,
        safe_divide(ai_autonomy_weighted_sum, ai_autonomy_observation_count) as ai_autonomy_score,
        safe_divide(ai_autonomy_ci_lower_weighted_sum, ai_autonomy_observation_count) as ai_autonomy_score_ci_lower,
        safe_divide(ai_autonomy_ci_upper_weighted_sum, ai_autonomy_observation_count) as ai_autonomy_score_ci_upper,
        human_only_time_observation_count,
        safe_divide(human_only_time_weighted_sum, human_only_time_observation_count) as human_only_time_mean,
        safe_divide(human_only_time_ci_lower_weighted_sum, human_only_time_observation_count) as human_only_time_mean_ci_lower,
        safe_divide(human_only_time_ci_upper_weighted_sum, human_only_time_observation_count) as human_only_time_mean_ci_upper,
        human_with_ai_time_observation_count,
        safe_divide(human_with_ai_time_weighted_sum, human_with_ai_time_observation_count) as human_with_ai_time_mean,
        safe_divide(human_with_ai_time_ci_lower_weighted_sum, human_with_ai_time_observation_count) as human_with_ai_time_mean_ci_lower,
        safe_divide(human_with_ai_time_ci_upper_weighted_sum, human_with_ai_time_observation_count) as human_with_ai_time_mean_ci_upper,
        human_only_ability_observation_count,
        requires_ai_task_count,
        safe_divide(requires_ai_task_count, human_only_ability_observation_count) as human_only_ability_requires_ai_rate
    from soc_aggregates

)

select
    geo_id,
    geo_name,
    geography,
    date_start,
    date_end,
    platform_and_product,
    use_case,
    soc_group,
    mapped_task_count,
    work_use_case_count,
    work_use_case_pct,
    task_success_observation_count,
    successful_task_count,
    task_success_rate,
    ai_autonomy_observation_count,
    ai_autonomy_score,
    ai_autonomy_score_ci_lower,
    ai_autonomy_score_ci_upper,
    human_only_time_observation_count,
    human_only_time_mean,
    human_only_time_mean_ci_lower,
    human_only_time_mean_ci_upper,
    human_with_ai_time_observation_count,
    human_with_ai_time_mean,
    human_with_ai_time_mean_ci_lower,
    human_with_ai_time_mean_ci_upper,
    1 - safe_divide(human_with_ai_time_mean, human_only_time_mean) as time_savings_ratio,
    1 - safe_divide(human_with_ai_time_mean_ci_upper, human_only_time_mean_ci_lower) as time_savings_ratio_ci_lower,
    1 - safe_divide(human_with_ai_time_mean_ci_lower, human_only_time_mean_ci_upper) as time_savings_ratio_ci_upper,
    human_only_ability_observation_count,
    requires_ai_task_count,
    human_only_ability_requires_ai_rate
from final
