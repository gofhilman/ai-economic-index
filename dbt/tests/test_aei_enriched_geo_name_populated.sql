select
    geo_id,
    geography,
    geo_name
from {{ ref('mart_aei_enriched_claude_ai_2025_11_13_to_2025_11_20') }}
where geo_name is null
   or trim(geo_name) = ''
