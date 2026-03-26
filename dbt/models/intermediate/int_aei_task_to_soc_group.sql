with onet_tasks as (

    select
        lower(trim(task)) as task_name,
        cast(soc_major_group as string) as soc_major_group
    from {{ ref('stg_onet_task_statements') }}
    where task is not null
      and soc_major_group is not null

),

soc_groups as (

    select distinct
        cast(soc_major_group as string) as soc_major_group,
        soc_or_o_net_soc_2019_title as soc_group
    from {{ ref('stg_soc_structure') }}
    where major_group is not null
      and soc_major_group is not null
      and soc_or_o_net_soc_2019_title is not null

)

select distinct
    onet_tasks.task_name,
    soc_groups.soc_group
from onet_tasks
inner join soc_groups
    using (soc_major_group)
