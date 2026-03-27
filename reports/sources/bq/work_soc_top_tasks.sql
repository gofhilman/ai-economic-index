with source_rows as (

    select
        lower(trim(cluster_name)) as task_name_normalized,
        cluster_name as task_name,
        value / 100 as onet_task_share
    from `ai-economic-index.output_dataset.mart_aei_enriched_claude_ai_2026_02_05_to_2026_02_12`
    where geo_id = 'GLOBAL'
      and facet = 'onet_task'
      and variable = 'onet_task_pct'
      and lower(trim(cluster_name)) not in ('none', 'not_classified')

),

task_mapping as (

    select distinct
        task_name,
        replace(replace(soc_group, ' Occupations', ''), ' Occupation', '') as soc_group_display
    from `ai-economic-index.output_dataset.int_aei_task_to_soc_group`

)

select
    source_rows.task_name,
    task_mapping.soc_group_display,
    source_rows.onet_task_share
from source_rows
inner join task_mapping
    on source_rows.task_name_normalized = task_mapping.task_name
order by soc_group_display, onet_task_share desc, task_name
