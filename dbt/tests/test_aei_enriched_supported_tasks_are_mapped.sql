with supported_tasks as (

    select distinct
        lower(trim(cluster_name)) as task_name
    from {{ ref('mart_aei_enriched_claude_ai_2025_11_13_to_2025_11_20') }}
    where facet = 'onet_task'
      and variable = 'onet_task_pct'
      and cluster_name != 'none'
      and not regexp_contains(lower(cluster_name), r'not_classified')

),

mapped_tasks as (

    select distinct task_name
    from {{ ref('int_aei_task_to_soc_group') }}

)

select
    supported_tasks.task_name
from supported_tasks
left join mapped_tasks
    on supported_tasks.task_name = mapped_tasks.task_name
where mapped_tasks.task_name is null
