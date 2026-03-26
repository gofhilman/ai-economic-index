with expected_to_map as (

    select distinct
        task_name
    from {{ ref('int_aei_task_shares_by_version') }}
    where task_name not in ('none', 'not_classified')

),

mapped_tasks as (

    select distinct
        task_name
    from {{ ref('int_aei_task_to_soc_group') }}

)

select
    expected_to_map.task_name
from expected_to_map
left join mapped_tasks
    on expected_to_map.task_name = mapped_tasks.task_name
where mapped_tasks.task_name is null
