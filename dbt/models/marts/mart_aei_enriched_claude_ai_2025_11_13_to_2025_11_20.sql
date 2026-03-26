with all_rows as (

    select *
    from {{ ref('int_aei_enriched_v4_scaffold_rows') }}

    union all

    select *
    from {{ ref('int_aei_enriched_v4_usage_metrics') }}

    union all

    select *
    from {{ ref('int_aei_enriched_v4_pct_index_metrics') }}

    union all

    select *
    from {{ ref('int_aei_enriched_v4_soc_metrics') }}

    union all

    select *
    from {{ ref('int_aei_enriched_v4_automation_metrics') }}

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
