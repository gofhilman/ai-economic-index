select
    geo_id
from {{ ref('mart_aei_enriched_claude_ai_2026_02_05_to_2026_02_12') }}
where geography = 'country'
  and not regexp_contains(geo_id, r'^[A-Z]{3}$')
