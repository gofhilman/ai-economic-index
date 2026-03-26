select
    geo_id,
    geography
from {{ ref('mart_aei_enriched_claude_ai_2025_11_13_to_2025_11_20') }}
where geography = 'country-state'
  and not regexp_contains(geo_id, r'^USA-[A-Z]{2}$')
