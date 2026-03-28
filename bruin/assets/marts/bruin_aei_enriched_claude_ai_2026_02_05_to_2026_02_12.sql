/* @bruin

name: output_dataset.bruin_aei_enriched_claude_ai_2026_02_05_to_2026_02_12
type: bq.sql
materialization:
  type: table

columns:
  - name: geo_id
    type: STRING
    description: Enriched geography identifier using ISO-3 for countries and USA-prefixed ISO 3166-2 style codes for US states.
  - name: geo_name
    type: STRING
    description: Human-readable geography name for the row.
  - name: geography
    type: STRING
    description: Geographic level in the enriched output.
  - name: date_start
    type: DATE
    description: Start date of the source collection window.
  - name: date_end
    type: DATE
    description: End date of the source collection window.
  - name: platform_and_product
    type: STRING
    description: Product label carried through from the clustered source.
  - name: facet
    type: STRING
    description: |
          Analysis dimension:
          **Geographic Facets:**
          - **country**: Country-level aggregations
          - **country-state**: Subnational region aggregations (ISO 3166-2 regions globally)

          **Content Facets:**
          - **onet_task**: O*NET occupational tasks
          - **collaboration**: Human-AI collaboration patterns
          - **request**: Request complexity levels (0=highest granularity, 1=middle granularity, 2=lowest granularity)
          - **multitasking**: Whether conversation involves single or multiple tasks
          - **human_only_ability**: Whether a human could complete the task without AI assistance
          - **use_case**: Use case categories (work, coursework, personal)
          - **task_success**: Whether the task was successfully completed

          **Numeric Facets** (continuous variables with distribution statistics):
          - **human_only_time**: Estimated time for a human to complete the task without AI
          - **human_with_ai_time**: Estimated time for a human to complete the task with AI assistance
          - **ai_autonomy**: Degree of AI autonomy in task completion
          - **human_education_years**: Estimated years of human education required for the task
          - **ai_education_years**: Estimated equivalent years of AI "education" demonstrated

          **Intersection Facets:**
          - **onet_task::collaboration**: Intersection of O*NET tasks and collaboration patterns
          - **onet_task::multitasking**: Intersection of O*NET tasks and multitasking status
          - **onet_task::human_only_ability**: Intersection of O*NET tasks and human-only ability
          - **onet_task::use_case**: Intersection of O*NET tasks and use case categories
          - **onet_task::task_success**: Intersection of O*NET tasks and task success
          - **onet_task::human_only_time**: Mean human-only time per O*NET task
          - **onet_task::human_with_ai_time**: Mean human-with-AI time per O*NET task
          - **onet_task::ai_autonomy**: Mean AI autonomy per O*NET task
          - **onet_task::human_education_years**: Mean human education years per O*NET task
          - **onet_task::ai_education_years**: Mean AI education years per O*NET task
          - **request::collaboration**: Intersection of request categories and collaboration patterns
          - **request::multitasking**: Intersection of request categories and multitasking status
          - **request::human_only_ability**: Intersection of request categories and human-only ability
          - **request::use_case**: Intersection of request categories and use case categories
          - **request::task_success**: Intersection of request categories and task success
          - **request::human_only_time**: Mean human-only time per request category
          - **request::human_with_ai_time**: Mean human-with-AI time per request category
          - **request::ai_autonomy**: Mean AI autonomy per request category
          - **request::human_education_years**: Mean human education years per request category
          - **request::ai_education_years**: Mean AI education years per request category

          **Enriched Facets**
  - name: level
    type: INT64
    description: Sub-level within facet (0-2).
  - name: variable
    type: STRING
    description: |
          Metric name:
          # Usage Metrics
          - **usage_count**: Total number of conversations/interactions in a geography
          - **usage_pct**: Percentage of total usage (relative to parent geography - global for countries, parent country for country-state regions)

          # Content Facet Metrics
          **O*NET Task Metrics**:
          - **onet_task_count**: Number of conversations using this specific O*NET task
          - **onet_task_pct**: Percentage of geographic total using this task
          - **onet_task_pct_index**: Specialization index comparing task usage to baseline (global for countries, parent country for country-state regions)
          - **onet_task_collaboration_count**: Number of conversations with both this task and collaboration pattern (intersection)
          - **onet_task_collaboration_pct**: Percentage of the base task's total that has this collaboration pattern (sums to 100% within each task)

          # Occupation Metrics
          - **soc_pct**: Percentage of classified O*NET tasks associated with this SOC major occupation group (e.g., Management, Computer and Mathematical)

          **Request Metrics**:
          - **request_count**: Number of conversations in this request category level
          - **request_pct**: Percentage of geographic total in this category
          - **request_collaboration_count**: Number of conversations with both this request category and collaboration pattern (intersection)
          - **request_collaboration_pct**: Percentage of the base request's total that has this collaboration pattern (sums to 100% within each request)

          **Collaboration Pattern Metrics**:
          - **collaboration_count**: Number of conversations with this collaboration pattern
          - **collaboration_pct**: Percentage of geographic total with this pattern

          **Multitasking Metrics**:
          - **multitasking_count**: Number of conversations with this multitasking status
          - **multitasking_pct**: Percentage of geographic total with this status

          **Human-Only Ability Metrics**:
          - **human_only_ability_count**: Number of conversations with this human-only ability status
          - **human_only_ability_pct**: Percentage of geographic total with this status

          **Use Case Metrics**:
          - **use_case_count**: Number of conversations in this use case category
          - **use_case_pct**: Percentage of geographic total in this category

          **Task Success Metrics**:
          - **task_success_count**: Number of conversations with this task success status
          - **task_success_pct**: Percentage of geographic total with this status

          # Numeric Facet Metrics
          For numeric facets (human_only_time, human_with_ai_time, ai_autonomy, human_education_years, ai_education_years), the following distribution statistics are available:

          - **{facet}_mean**: Mean value across all conversations
          - **{facet}_median**: Median value across all conversations
          - **{facet}_stdev**: Standard deviation of values
          - **{facet}_mean_ci_lower**: Lower bound of 95% confidence interval for the mean
          - **{facet}_mean_ci_upper**: Upper bound of 95% confidence interval for the mean
          - **{facet}_median_ci_lower**: Lower bound of 95% confidence interval for the median
          - **{facet}_median_ci_upper**: Upper bound of 95% confidence interval for the median
          - **{facet}_count**: Total number of observations for this facet
          - **{facet}_histogram_count**: Count of observations in each histogram bin (one row per bin, bin range in cluster_name, e.g., "[1.0, 1.0)")
          - **{facet}_histogram_pct**: Percentage of observations in each histogram bin (one row per bin)

          For numeric intersection facets (e.g., onet_task::human_only_time), the same metrics are available per category (e.g., per O*NET task), with cluster_name containing the category identifier:
          - **{base}_{numeric}_mean**: Mean value for this category
          - **{base}_{numeric}_median**: Median value for this category
          - **{base}_{numeric}_stdev**: Standard deviation for this category
          - **{base}_{numeric}_count**: Number of observations for this category
          - **{base}_{numeric}_mean_ci_lower/upper**: 95% CI bounds for the mean
          - **{base}_{numeric}_median_ci_lower/upper**: 95% CI bounds for the median
  - name: cluster_name
    type: STRING
    description: Specific entity within facet (task, pattern, etc.). For intersections, format is "base::category".
  - name: value
    type: FLOAT64
    description: Numeric value for the metric row.

@bruin */

SELECT * FROM output_dataset.mart_aei_enriched_claude_ai_2026_02_05_to_2026_02_12
