select
    geo_id,
    geography,
    date_start,
    date_end,
    platform_and_product,
    sum(value) as total_pct
from {{ ref('mart_aei_enriched_claude_ai_2025_11_13_to_2025_11_20') }}
where variable = 'soc_pct'
group by 1, 2, 3, 4, 5
having abs(sum(value) - 100) > 0.001
