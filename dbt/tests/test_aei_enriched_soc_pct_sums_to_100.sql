select
    geo_id,
    geography,
    date_start,
    date_end,
    platform_and_product,
    sum(value) as total_pct
from {{ ref('mart_aei_enriched_claude_ai_2026_02_05_to_2026_02_12') }}
where variable = 'soc_pct'
group by 1, 2, 3, 4, 5
having abs(sum(value) - 100) > 0.001
