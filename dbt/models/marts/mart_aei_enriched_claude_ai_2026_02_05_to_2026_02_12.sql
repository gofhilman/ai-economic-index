with all_rows as (

    select *
    from {{ ref('int_aei_enriched_v5_scaffold_rows') }}

    union all

    select *
    from {{ ref('int_aei_enriched_v5_usage_metrics') }}

    union all

    select *
    from {{ ref('int_aei_enriched_v5_pct_index_metrics') }}

    union all

    select *
    from {{ ref('int_aei_enriched_v5_soc_metrics') }}

    union all

    select *
    from {{ ref('int_aei_enriched_v5_automation_metrics') }}

)

select
    geo_id,
    geo_name,
    geography,
    date_start,
    date_end,
    platform_and_product,
    facet,
    level,
    variable,
    cluster_name,
    value
from all_rows
