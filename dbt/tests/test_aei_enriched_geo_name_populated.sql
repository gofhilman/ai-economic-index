select
    geo_id,
    geography,
    geo_name
from {{ ref('mart_aei_enriched_claude_ai_2026_02_05_to_2026_02_12') }}
where geo_name is null
   or trim(geo_name) = ''
