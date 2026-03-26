with automation_rows as (

    select
        geo_id,
        geography,
        date_start,
        date_end,
        platform_and_product,
        sum(case when variable = 'automation_pct' then value else 0 end) as automation_pct,
        sum(case when variable = 'augmentation_pct' then value else 0 end) as augmentation_pct,
        countif(variable = 'automation_pct') as automation_row_count,
        countif(variable = 'augmentation_pct') as augmentation_row_count
    from {{ ref('mart_aei_enriched_claude_ai_2026_02_05_to_2026_02_12') }}
    where facet = 'collaboration_automation_augmentation'
    group by 1, 2, 3, 4, 5

)

select *
from automation_rows
where automation_row_count != 1
   or augmentation_row_count != 1
   or abs(automation_pct + augmentation_pct - 100) > 0.001
