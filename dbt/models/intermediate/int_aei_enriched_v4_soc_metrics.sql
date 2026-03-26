with scaffold_rows as (

    select *
    from {{ ref('int_aei_enriched_v4_scaffold_rows') }}

),

filtered_countries as (

    select distinct geo_id
    from scaffold_rows
    where geography = 'country'
      and facet = 'country'
      and variable = 'usage_count'
      and value >= 200

),

filtered_us_states as (

    select distinct geo_id
    from scaffold_rows
    where geography = 'country-state'
      and facet = 'country-state'
      and variable = 'usage_count'
      and value >= 100

),

soc_input_rows as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        cluster_name,
        value
    from scaffold_rows
    where facet = 'onet_task'
      and variable = 'onet_task_pct'
      and (
            geography = 'global'
            or (geography = 'country' and geo_id in (select geo_id from filtered_countries))
            or (geography = 'country-state' and geo_id in (select geo_id from filtered_us_states))
        )

),

soc_mapped_rows as (

    select
        soc_input_rows.geo_id,
        soc_input_rows.geo_name,
        soc_input_rows.geography,
        soc_input_rows.date_start,
        soc_input_rows.date_end,
        soc_input_rows.platform_and_product,
        replace(replace(int_aei_task_to_soc_group.soc_group, ' Occupations', ''), ' Occupation', '') as cluster_name,
        soc_input_rows.value
    from soc_input_rows
    inner join {{ ref('int_aei_task_to_soc_group') }} as int_aei_task_to_soc_group
        on lower(trim(soc_input_rows.cluster_name)) = int_aei_task_to_soc_group.task_name
    where soc_input_rows.cluster_name != 'none'
      and not regexp_contains(lower(soc_input_rows.cluster_name), r'not_classified')

),

soc_totals as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        cluster_name,
        sum(value) as soc_value
    from soc_mapped_rows
    group by 1, 2, 3, 4, 5, 6, 7

),

soc_not_classified_totals as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        sum(value) as not_classified_value
    from soc_input_rows
    where cluster_name = 'none'
       or regexp_contains(lower(cluster_name), r'not_classified')
    group by 1, 2, 3, 4, 5, 6

),

soc_combined_totals as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        sum(soc_value) as mapped_total
    from soc_totals
    group by 1, 2, 3, 4, 5, 6

),

soc_denominators as (

    select
        soc_combined_totals.geo_id,
        soc_combined_totals.geo_name,
        soc_combined_totals.geography,
        soc_combined_totals.date_start,
        soc_combined_totals.date_end,
        soc_combined_totals.platform_and_product,
        soc_combined_totals.mapped_total + coalesce(soc_not_classified_totals.not_classified_value, 0) as total_pct,
        coalesce(soc_not_classified_totals.not_classified_value, 0) as not_classified_value
    from soc_combined_totals
    left join soc_not_classified_totals
        on soc_combined_totals.geo_id = soc_not_classified_totals.geo_id
       and soc_combined_totals.geography = soc_not_classified_totals.geography
       and soc_combined_totals.date_start = soc_not_classified_totals.date_start
       and soc_combined_totals.date_end = soc_not_classified_totals.date_end
       and soc_combined_totals.platform_and_product = soc_not_classified_totals.platform_and_product

    union all

    select
        soc_not_classified_totals.geo_id,
        soc_not_classified_totals.geo_name,
        soc_not_classified_totals.geography,
        soc_not_classified_totals.date_start,
        soc_not_classified_totals.date_end,
        soc_not_classified_totals.platform_and_product,
        soc_not_classified_totals.not_classified_value as total_pct,
        soc_not_classified_totals.not_classified_value
    from soc_not_classified_totals
    left join soc_combined_totals
        on soc_not_classified_totals.geo_id = soc_combined_totals.geo_id
       and soc_not_classified_totals.geography = soc_combined_totals.geography
       and soc_not_classified_totals.date_start = soc_combined_totals.date_start
       and soc_not_classified_totals.date_end = soc_combined_totals.date_end
       and soc_not_classified_totals.platform_and_product = soc_combined_totals.platform_and_product
    where soc_combined_totals.geo_id is null

),

soc_pct_rows as (

    select
        soc_totals.geo_id,
        soc_totals.geo_name,
        soc_totals.geography,
        soc_totals.date_start,
        soc_totals.date_end,
        soc_totals.platform_and_product,
        'soc_occupation' as facet,
        cast(0 as int64) as level,
        'soc_pct' as variable,
        soc_totals.cluster_name,
        safe_divide(soc_totals.soc_value * 100, soc_denominators.total_pct) as value
    from soc_totals
    inner join soc_denominators
        on soc_totals.geo_id = soc_denominators.geo_id
       and soc_totals.geography = soc_denominators.geography
       and soc_totals.date_start = soc_denominators.date_start
       and soc_totals.date_end = soc_denominators.date_end
       and soc_totals.platform_and_product = soc_denominators.platform_and_product
    where soc_denominators.total_pct > 0

    union all

    select
        soc_denominators.geo_id,
        soc_denominators.geo_name,
        soc_denominators.geography,
        soc_denominators.date_start,
        soc_denominators.date_end,
        soc_denominators.platform_and_product,
        'soc_occupation' as facet,
        cast(0 as int64) as level,
        'soc_pct' as variable,
        'not_classified' as cluster_name,
        safe_divide(soc_denominators.not_classified_value * 100, soc_denominators.total_pct) as value
    from soc_denominators
    where soc_denominators.total_pct > 0
      and soc_denominators.not_classified_value > 0

)

select * from soc_pct_rows
