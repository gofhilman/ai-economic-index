with scaffold_rows as (

    select *
    from {{ ref('int_aei_enriched_v5_scaffold_rows') }}

),

{{ aei_enriched_filtered_geography_ctes('scaffold_rows') }},

pct_source_rows as (

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
    from scaffold_rows
    where variable in ('onet_task_pct', 'collaboration_pct', 'request_pct')
      and {{ aei_enriched_is_classified_cluster('cluster_name') }}

),

global_pct_baselines as (

    select
        date_start,
        date_end,
        platform_and_product,
        facet,
        level,
        variable,
        cluster_name,
        value as baseline_value
    from pct_source_rows
    where geography = 'global'
      and geo_id = 'GLOBAL'

),

us_pct_baselines as (

    select
        date_start,
        date_end,
        platform_and_product,
        facet,
        level,
        variable,
        cluster_name,
        value as baseline_value
    from pct_source_rows
    where geography = 'country'
      and geo_id = 'USA'

),

country_pct_index_rows as (

    select
        pct_source_rows.geo_id,
        pct_source_rows.geo_name,
        pct_source_rows.geography,
        pct_source_rows.date_start,
        pct_source_rows.date_end,
        pct_source_rows.platform_and_product,
        pct_source_rows.facet,
        pct_source_rows.level,
        replace(pct_source_rows.variable, '_pct', '_pct_index') as variable,
        pct_source_rows.cluster_name,
        safe_divide(pct_source_rows.value, global_pct_baselines.baseline_value) as value
    from pct_source_rows
    inner join filtered_countries
        on pct_source_rows.geo_id = filtered_countries.geo_id
    inner join global_pct_baselines
        on pct_source_rows.date_start = global_pct_baselines.date_start
       and pct_source_rows.date_end = global_pct_baselines.date_end
       and pct_source_rows.platform_and_product = global_pct_baselines.platform_and_product
       and pct_source_rows.facet = global_pct_baselines.facet
       and pct_source_rows.level = global_pct_baselines.level
       and pct_source_rows.variable = global_pct_baselines.variable
       and pct_source_rows.cluster_name = global_pct_baselines.cluster_name
    where pct_source_rows.geography = 'country'
      and global_pct_baselines.baseline_value > 0

),

us_state_pct_index_rows as (

    select
        pct_source_rows.geo_id,
        pct_source_rows.geo_name,
        pct_source_rows.geography,
        pct_source_rows.date_start,
        pct_source_rows.date_end,
        pct_source_rows.platform_and_product,
        pct_source_rows.facet,
        pct_source_rows.level,
        replace(pct_source_rows.variable, '_pct', '_pct_index') as variable,
        pct_source_rows.cluster_name,
        safe_divide(pct_source_rows.value, us_pct_baselines.baseline_value) as value
    from pct_source_rows
    inner join filtered_us_states
        on pct_source_rows.geo_id = filtered_us_states.geo_id
    inner join us_pct_baselines
        on pct_source_rows.date_start = us_pct_baselines.date_start
       and pct_source_rows.date_end = us_pct_baselines.date_end
       and pct_source_rows.platform_and_product = us_pct_baselines.platform_and_product
       and pct_source_rows.facet = us_pct_baselines.facet
       and pct_source_rows.level = us_pct_baselines.level
       and pct_source_rows.variable = us_pct_baselines.variable
       and pct_source_rows.cluster_name = us_pct_baselines.cluster_name
    where pct_source_rows.geography = 'country-state'
      and us_pct_baselines.baseline_value > 0

)

select * from country_pct_index_rows
union all
select * from us_state_pct_index_rows
