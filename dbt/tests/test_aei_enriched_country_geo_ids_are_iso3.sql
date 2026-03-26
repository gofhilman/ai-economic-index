select
    geo_id
from {{ ref('mart_aei_enriched_claude_ai_2025_11_13_to_2025_11_20') }}
where geography = 'country'
  and not regexp_contains(geo_id, r'^[A-Z]{3}$')
