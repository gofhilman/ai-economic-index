with totals as (

    select
        sum(ai_autonomy_observation_count) as ai_autonomy_observation_count,
        sum(human_only_time_observation_count) as human_only_time_observation_count,
        sum(human_with_ai_time_observation_count) as human_with_ai_time_observation_count
    from {{ ref('mart_aei_work_soc_outcomes') }}

)

select *
from totals
where ai_autonomy_observation_count = 0
   or human_only_time_observation_count = 0
   or human_with_ai_time_observation_count = 0
