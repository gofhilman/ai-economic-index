select
    geo_id,
    geography,
    variable,
    cluster_name
from {{ ref('mart_aei_enriched_claude_ai_2025_11_13_to_2025_11_20') }}
where regexp_contains(variable, r'_pct_index$')
  and (
        cluster_name in ('none', 'not_classified')
        or regexp_contains(lower(cluster_name), r'not_classified')
    )
