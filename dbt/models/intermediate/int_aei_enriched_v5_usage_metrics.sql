with scaffold_rows as (

    select *
    from {{ ref('int_aei_enriched_v5_scaffold_rows') }}

),

{{ aei_enriched_filtered_geography_ctes('scaffold_rows') }},

population_rows as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        value as population
    from scaffold_rows
    where variable = 'working_age_pop'

),

usage_count_rows as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        facet,
        level,
        cluster_name,
        value as usage_count
    from scaffold_rows
    where variable = 'usage_count'

),

usage_per_capita_rows as (

    select
        usage_count_rows.geo_id,
        usage_count_rows.geo_name,
        usage_count_rows.geography,
        usage_count_rows.date_start,
        usage_count_rows.date_end,
        usage_count_rows.platform_and_product,
        usage_count_rows.facet,
        usage_count_rows.level,
        'usage_per_capita' as variable,
        usage_count_rows.cluster_name,
        safe_divide(usage_count_rows.usage_count, population_rows.population) as value
    from usage_count_rows
    inner join population_rows
        on usage_count_rows.geo_id = population_rows.geo_id
       and usage_count_rows.geography = population_rows.geography
       and usage_count_rows.date_start = population_rows.date_start
       and usage_count_rows.date_end = population_rows.date_end
       and usage_count_rows.platform_and_product = population_rows.platform_and_product
    where population_rows.population > 0

),

country_usage_totals as (

    select
        usage_count_rows.date_start,
        usage_count_rows.date_end,
        usage_count_rows.platform_and_product,
        sum(usage_count_rows.usage_count) as total_usage,
        sum(population_rows.population) as total_population
    from usage_count_rows
    inner join population_rows
        on usage_count_rows.geo_id = population_rows.geo_id
       and usage_count_rows.geography = population_rows.geography
       and usage_count_rows.date_start = population_rows.date_start
       and usage_count_rows.date_end = population_rows.date_end
       and usage_count_rows.platform_and_product = population_rows.platform_and_product
    inner join filtered_countries
        on usage_count_rows.geo_id = filtered_countries.geo_id
    where usage_count_rows.geography = 'country'
      and population_rows.population > 0
    group by 1, 2, 3

),

us_state_usage_totals as (

    select
        usage_count_rows.date_start,
        usage_count_rows.date_end,
        usage_count_rows.platform_and_product,
        sum(usage_count_rows.usage_count) as total_usage,
        sum(population_rows.population) as total_population
    from usage_count_rows
    inner join population_rows
        on usage_count_rows.geo_id = population_rows.geo_id
       and usage_count_rows.geography = population_rows.geography
       and usage_count_rows.date_start = population_rows.date_start
       and usage_count_rows.date_end = population_rows.date_end
       and usage_count_rows.platform_and_product = population_rows.platform_and_product
    inner join filtered_us_states
        on usage_count_rows.geo_id = filtered_us_states.geo_id
    where usage_count_rows.geography = 'country-state'
      and population_rows.population > 0
    group by 1, 2, 3

),

country_usage_per_capita_index_rows as (

    select
        usage_count_rows.geo_id,
        usage_count_rows.geo_name,
        usage_count_rows.geography,
        usage_count_rows.date_start,
        usage_count_rows.date_end,
        usage_count_rows.platform_and_product,
        usage_count_rows.facet,
        usage_count_rows.level,
        'usage_per_capita_index' as variable,
        usage_count_rows.cluster_name,
        safe_divide(
            safe_divide(usage_count_rows.usage_count, country_usage_totals.total_usage),
            safe_divide(population_rows.population, country_usage_totals.total_population)
        ) as value
    from usage_count_rows
    inner join population_rows
        on usage_count_rows.geo_id = population_rows.geo_id
       and usage_count_rows.geography = population_rows.geography
       and usage_count_rows.date_start = population_rows.date_start
       and usage_count_rows.date_end = population_rows.date_end
       and usage_count_rows.platform_and_product = population_rows.platform_and_product
    inner join country_usage_totals
        on usage_count_rows.date_start = country_usage_totals.date_start
       and usage_count_rows.date_end = country_usage_totals.date_end
       and usage_count_rows.platform_and_product = country_usage_totals.platform_and_product
    where usage_count_rows.geography = 'country'
      and population_rows.population > 0
      and country_usage_totals.total_usage > 0
      and country_usage_totals.total_population > 0

),

us_state_usage_per_capita_index_rows as (

    select
        usage_count_rows.geo_id,
        usage_count_rows.geo_name,
        usage_count_rows.geography,
        usage_count_rows.date_start,
        usage_count_rows.date_end,
        usage_count_rows.platform_and_product,
        usage_count_rows.facet,
        usage_count_rows.level,
        'usage_per_capita_index' as variable,
        usage_count_rows.cluster_name,
        safe_divide(
            safe_divide(usage_count_rows.usage_count, us_state_usage_totals.total_usage),
            safe_divide(population_rows.population, us_state_usage_totals.total_population)
        ) as value
    from usage_count_rows
    inner join population_rows
        on usage_count_rows.geo_id = population_rows.geo_id
       and usage_count_rows.geography = population_rows.geography
       and usage_count_rows.date_start = population_rows.date_start
       and usage_count_rows.date_end = population_rows.date_end
       and usage_count_rows.platform_and_product = population_rows.platform_and_product
    inner join us_state_usage_totals
        on usage_count_rows.date_start = us_state_usage_totals.date_start
       and usage_count_rows.date_end = us_state_usage_totals.date_end
       and usage_count_rows.platform_and_product = us_state_usage_totals.platform_and_product
    where usage_count_rows.geography = 'country-state'
      and population_rows.population > 0
      and us_state_usage_totals.total_usage > 0
      and us_state_usage_totals.total_population > 0

),

usage_per_capita_index_rows as (

    select * from country_usage_per_capita_index_rows
    union all
    select * from us_state_usage_per_capita_index_rows

),

filtered_usage_index_rows as (

    select *
    from usage_per_capita_index_rows
    where {{ aei_enriched_threshold_eligible_geography_condition() }}

),

usage_tier_thresholds as (

    select distinct
        geography,
        date_start,
        date_end,
        platform_and_product,
        percentile_cont(value, 0.25) over (
            partition by geography, date_start, date_end, platform_and_product
        ) as q25,
        percentile_cont(value, 0.5) over (
            partition by geography, date_start, date_end, platform_and_product
        ) as q50,
        percentile_cont(value, 0.75) over (
            partition by geography, date_start, date_end, platform_and_product
        ) as q75
    from filtered_usage_index_rows
    where value > 0

),

usage_tier_rows as (

    select
        usage_per_capita_index_rows.geo_id,
        usage_per_capita_index_rows.geo_name,
        usage_per_capita_index_rows.geography,
        usage_per_capita_index_rows.date_start,
        usage_per_capita_index_rows.date_end,
        usage_per_capita_index_rows.platform_and_product,
        usage_per_capita_index_rows.facet,
        usage_per_capita_index_rows.level,
        'usage_tier' as variable,
        'Minimal' as cluster_name,
        cast(0 as float64) as value
    from usage_per_capita_index_rows
    where usage_per_capita_index_rows.geography in ('country', 'country-state')
      and usage_per_capita_index_rows.value = 0

    union all

    select
        usage_per_capita_index_rows.geo_id,
        usage_per_capita_index_rows.geo_name,
        usage_per_capita_index_rows.geography,
        usage_per_capita_index_rows.date_start,
        usage_per_capita_index_rows.date_end,
        usage_per_capita_index_rows.platform_and_product,
        usage_per_capita_index_rows.facet,
        usage_per_capita_index_rows.level,
        'usage_tier' as variable,
        case
            when usage_per_capita_index_rows.value <= usage_tier_thresholds.q25
                then 'Emerging (bottom 25%)'
            when usage_per_capita_index_rows.value <= usage_tier_thresholds.q50
                then 'Lower middle (25-50%)'
            when usage_per_capita_index_rows.value <= usage_tier_thresholds.q75
                then 'Upper middle (50-75%)'
            else 'Leading (top 25%)'
        end as cluster_name,
        case
            when usage_per_capita_index_rows.value <= usage_tier_thresholds.q25
                then cast(1 as float64)
            when usage_per_capita_index_rows.value <= usage_tier_thresholds.q50
                then cast(2 as float64)
            when usage_per_capita_index_rows.value <= usage_tier_thresholds.q75
                then cast(3 as float64)
            else cast(4 as float64)
        end as value
    from usage_per_capita_index_rows
    inner join usage_tier_thresholds
        on usage_per_capita_index_rows.geography = usage_tier_thresholds.geography
       and usage_per_capita_index_rows.date_start = usage_tier_thresholds.date_start
       and usage_per_capita_index_rows.date_end = usage_tier_thresholds.date_end
       and usage_per_capita_index_rows.platform_and_product = usage_tier_thresholds.platform_and_product
    where usage_per_capita_index_rows.geography in ('country', 'country-state')
      and usage_per_capita_index_rows.value > 0

)

select * from usage_per_capita_rows
union all
select * from usage_per_capita_index_rows
union all
select * from usage_tier_rows
