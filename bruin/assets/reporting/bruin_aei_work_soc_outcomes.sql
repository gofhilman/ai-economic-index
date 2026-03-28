/* @bruin

name: output_dataset.bruin_aei_work_soc_outcomes
type: bq.sql
materialization:
  type: table

columns:
  - name: geo_id
    type: STRING
    description: Geographic identifier fixed to `GLOBAL` for this reporting slice.
  - name: geo_name
    type: STRING
    description: Human-readable geography label for the global slice.
  - name: geography
    type: STRING
    description: Geography grain from the source mart, expected to be `global`.
  - name: date_start
    type: DATE
    description: Start date of the AEI reporting window.
  - name: date_end
    type: DATE
    description: End date of the AEI reporting window.
  - name: platform_and_product
    type: STRING
    description: Source platform/product label carried through from the enriched mart.
  - name: use_case
    type: STRING
    description: Use-case filter applied to the reporting mart, fixed to `work`.
  - name: soc_group
    type: STRING
    description: SOC major-group title, normalized to match existing reporting marts.
  - name: mapped_task_count
    type: INT64
    description: Count of distinct mapped O*NET tasks with non-zero work usage in the SOC group.
  - name: work_use_case_count
    type: FLOAT64
    description: Sum of work-use-case conversation counts across mapped tasks in the SOC group.
  - name: work_use_case_pct
    type: FLOAT64
    description: SOC share of mapped global work-use-case conversations.
  - name: task_success_observation_count
    type: FLOAT64
    description: Estimated number of work observations contributing to task success.
  - name: successful_task_count
    type: FLOAT64
    description: Estimated number of successful work observations in the SOC group.
  - name: task_success_rate
    type: FLOAT64
    description: Estimated work-filtered task success share for the SOC group.
  - name: ai_autonomy_observation_count
    type: FLOAT64
    description: Estimated number of work observations contributing to the AI autonomy metric.
  - name: ai_autonomy_score
    type: FLOAT64
    description: Work-weighted AI autonomy score for the SOC group.
  - name: ai_autonomy_score_ci_lower
    type: FLOAT64
    description: Lower 95% confidence bound for the AI autonomy score.
  - name: ai_autonomy_score_ci_upper
    type: FLOAT64
    description: Upper 95% confidence bound for the AI autonomy score.
  - name: human_only_time_observation_count
    type: FLOAT64
    description: Estimated number of work observations contributing to the human-only time metric.
  - name: human_only_time_median
    type: FLOAT64
    description: Work-weighted median time for a human to complete the task without AI.
  - name: human_only_time_median_ci_lower
    type: FLOAT64
    description: Lower 95% confidence bound for human-only time.
  - name: human_only_time_median_ci_upper
    type: FLOAT64
    description: Upper 95% confidence bound for human-only time.
  - name: human_with_ai_time_observation_count
    type: FLOAT64
    description: Estimated number of work observations contributing to the human-with-AI time metric.
  - name: human_with_ai_time_median
    type: FLOAT64
    description: Work-weighted median time for a human to complete the task with AI assistance.
  - name: human_with_ai_time_median_ci_lower
    type: FLOAT64
    description: Lower 95% confidence bound for human-with-AI time.
  - name: human_with_ai_time_median_ci_upper
    type: FLOAT64
    description: Upper 95% confidence bound for human-with-AI time.
  - name: time_savings_ratio
    type: FLOAT64
    description: Ratio defined as `1 - (human_with_ai_time_median / human_only_time_median)`.
  - name: time_savings_ratio_ci_lower
    type: FLOAT64
    description: Conservative lower confidence bound for time savings.
  - name: time_savings_ratio_ci_upper
    type: FLOAT64
    description: Optimistic upper confidence bound for time savings.
  - name: human_only_ability_observation_count
    type: FLOAT64
    description: Estimated number of work observations contributing to human-only ability.
  - name: requires_ai_task_count
    type: FLOAT64
    description: Estimated number of work observations that could not be done without AI.
  - name: human_only_ability_requires_ai_rate
    type: FLOAT64
    description: Estimated share of work observations that could not be completed without AI.

@bruin */

SELECT * FROM output_dataset.mart_aei_work_soc_outcomes
