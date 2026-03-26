select
    geo_id,
    geography,
    cluster_name,
    value
from {{ ref('mart_aei_enriched_claude_ai_2025_11_13_to_2025_11_20') }}
where variable = 'usage_tier'
  and (
        cluster_name not in (
            'Minimal',
            'Emerging (bottom 25%)',
            'Lower middle (25-50%)',
            'Upper middle (50-75%)',
            'Leading (top 25%)'
        )
        or value not in (0, 1, 2, 3, 4)
    )
