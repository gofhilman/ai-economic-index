select
    geo_id,
    geography
from {{ ref('mart_aei_enriched_claude_ai_2026_02_05_to_2026_02_12') }}
where geography = 'country-state'
  and not regexp_contains(geo_id, r'^USA-[A-Z]{2}$')
