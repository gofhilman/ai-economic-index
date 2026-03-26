with excluded_countries as (

    select 'AF' as iso_alpha_2 union all
    select 'BY' union all
    select 'CD' union all
    select 'CF' union all
    select 'CN' union all
    select 'CU' union all
    select 'ER' union all
    select 'ET' union all
    select 'HK' union all
    select 'IR' union all
    select 'KP' union all
    select 'LY' union all
    select 'ML' union all
    select 'MM' union all
    select 'MO' union all
    select 'NI' union all
    select 'RU' union all
    select 'SD' union all
    select 'SO' union all
    select 'SS' union all
    select 'SY' union all
    select 'VE' union all
    select 'YE'

),

iso_country_codes as (

    select distinct
        upper(iso_alpha_2) as iso_alpha_2,
        upper(iso_alpha_3) as iso_alpha_3,
        country_name
    from {{ ref('stg_iso_country_codes') }}

),

us_state_codes as (

    select distinct
        upper(stusab) as state_code,
        state_name
    from {{ ref('stg_census_state_codes') }}

),

country_population as (

    select distinct
        upper(pop.iso_alpha_3) as iso_alpha_3,
        upper(coalesce(pop.country_code, iso_country_codes.iso_alpha_2)) as iso_alpha_2,
        coalesce(pop.country_name, iso_country_codes.country_name, upper(pop.iso_alpha_3)) as country_name,
        cast(pop.working_age_pop as float64) as working_age_pop
    from {{ ref('stg_working_age_pop_2024_country') }} as pop
    left join iso_country_codes
        on upper(pop.iso_alpha_3) = iso_country_codes.iso_alpha_3
    where upper(coalesce(pop.country_code, iso_country_codes.iso_alpha_2)) not in (
        select iso_alpha_2 from excluded_countries
    )

),

country_gdp as (

    select distinct
        upper(iso_alpha_3) as iso_alpha_3,
        cast(gdp_total as float64) as gdp_total
    from {{ ref('stg_gdp_2024_country') }}

),

country_external as (

    select
        country_population.iso_alpha_3 as geo_id,
        country_population.country_name as geo_name,
        country_population.working_age_pop,
        safe_divide(country_gdp.gdp_total, country_population.working_age_pop) as gdp_per_working_age_capita
    from country_population
    left join country_gdp
        using (iso_alpha_3)

),

us_state_population as (

    select distinct
        upper(pop.state_code) as state_code,
        coalesce(us_state_codes.state_name, pop.state, upper(pop.state_code)) as geo_name,
        cast(pop.working_age_pop as float64) as working_age_pop
    from {{ ref('stg_working_age_pop_2024_us_state') }} as pop
    left join us_state_codes
        on upper(pop.state_code) = us_state_codes.state_code

),

us_state_gdp as (

    select distinct
        upper(state_code) as state_code,
        cast(gdp_total as float64) as gdp_total
    from {{ ref('stg_gdp_2024_us_state') }}

),

us_state_external as (

    select
        concat('USA-', us_state_population.state_code) as geo_id,
        us_state_population.geo_name,
        us_state_population.working_age_pop,
        safe_divide(us_state_gdp.gdp_total, us_state_population.working_age_pop) as gdp_per_working_age_capita
    from us_state_population
    left join us_state_gdp
        using (state_code)

),

source_rows as (

    select
        geo_id,
        geography,
        date_start,
        date_end,
        platform_and_product,
        facet,
        cast(level as int64) as level,
        variable,
        coalesce(cluster_name, '') as cluster_name,
        cast(value as float64) as value
    from {{ ref('stg_aei_clustered_claude_ai_2026_02_05_to_2026_02_12') }}
    where geography in ('global', 'country')
       or (
            geography = 'country-state'
            and (
                regexp_contains(upper(geo_id), r'^US-[A-Z]{2}$')
                or regexp_contains(upper(geo_id), r'^USA-[A-Z]{2}$')
            )
        )

),

normalized_base_rows as (

    select
        case
            when source_rows.geography = 'global' then 'GLOBAL'
            when source_rows.geography = 'country'
                then coalesce(country_iso2.iso_alpha_3, country_iso3.iso_alpha_3, upper(source_rows.geo_id))
            when source_rows.geography = 'country-state'
                 and regexp_contains(upper(source_rows.geo_id), r'^US-[A-Z]{2}$')
                then regexp_replace(upper(source_rows.geo_id), r'^US-', 'USA-')
            else upper(source_rows.geo_id)
        end as geo_id,
        source_rows.geography,
        source_rows.date_start,
        source_rows.date_end,
        source_rows.platform_and_product,
        source_rows.facet,
        source_rows.level,
        source_rows.variable,
        source_rows.cluster_name,
        source_rows.value
    from source_rows
    left join iso_country_codes as country_iso2
        on source_rows.geography = 'country'
       and upper(source_rows.geo_id) = country_iso2.iso_alpha_2
    left join iso_country_codes as country_iso3
        on source_rows.geography = 'country'
       and upper(source_rows.geo_id) = country_iso3.iso_alpha_3
    where source_rows.geography != 'country'
       or country_iso2.iso_alpha_3 is not null
       or country_iso3.iso_alpha_3 is not null

),

geo_name_candidates as (

    select
        'GLOBAL' as geo_id,
        'global' as geography,
        'global' as geo_name,
        1 as priority

    union all

    select
        geo_id,
        'country' as geography,
        geo_name,
        1 as priority
    from country_external

    union all

    select
        geo_id,
        'country-state' as geography,
        geo_name,
        1 as priority
    from us_state_external

    union all

    select
        base.geo_id,
        base.geography,
        case
            when base.geography = 'global' then 'global'
            when base.geography = 'country'
                then coalesce(country_external.geo_name, iso_country_codes.country_name, base.geo_id)
            when base.geography = 'country-state'
                then coalesce(us_state_external.geo_name, base.geo_id)
            else base.geo_id
        end as geo_name,
        case
            when base.geography = 'global' then 1
            when base.geography = 'country'
                 and coalesce(country_external.geo_name, iso_country_codes.country_name) is not null
                then 2
            when base.geography = 'country-state'
                 and us_state_external.geo_name is not null
                then 2
            else 3
        end as priority
    from normalized_base_rows as base
    left join country_external
        on base.geography = 'country'
       and base.geo_id = country_external.geo_id
    left join iso_country_codes
        on base.geography = 'country'
       and base.geo_id = iso_country_codes.iso_alpha_3
    left join us_state_external
        on base.geography = 'country-state'
       and base.geo_id = us_state_external.geo_id

),

geo_names as (

    select
        geo_id,
        geography,
        geo_name
    from geo_name_candidates
    qualify row_number() over (
        partition by geo_id, geography
        order by priority, geo_name
    ) = 1

),

date_platform_combos as (

    select distinct
        date_start,
        date_end,
        platform_and_product
    from normalized_base_rows

),

existing_country_usage as (

    select distinct
        geo_id,
        date_start,
        date_end,
        platform_and_product
    from normalized_base_rows
    where geography = 'country'
      and facet = 'country'
      and variable = 'usage_count'

),

existing_us_state_usage as (

    select distinct
        geo_id,
        date_start,
        date_end,
        platform_and_product
    from normalized_base_rows
    where geography = 'country-state'
      and facet = 'country-state'
      and variable = 'usage_count'

),

missing_country_usage_rows as (

    select
        country_external.geo_id,
        'country' as geography,
        date_platform_combos.date_start,
        date_platform_combos.date_end,
        date_platform_combos.platform_and_product,
        'country' as facet,
        cast(0 as int64) as level,
        'usage_count' as variable,
        '' as cluster_name,
        cast(0 as float64) as value
    from country_external
    cross join date_platform_combos
    left join existing_country_usage
        on country_external.geo_id = existing_country_usage.geo_id
       and date_platform_combos.date_start = existing_country_usage.date_start
       and date_platform_combos.date_end = existing_country_usage.date_end
       and date_platform_combos.platform_and_product = existing_country_usage.platform_and_product
    where existing_country_usage.geo_id is null

    union all

    select
        country_external.geo_id,
        'country' as geography,
        date_platform_combos.date_start,
        date_platform_combos.date_end,
        date_platform_combos.platform_and_product,
        'country' as facet,
        cast(0 as int64) as level,
        'usage_pct' as variable,
        '' as cluster_name,
        cast(0 as float64) as value
    from country_external
    cross join date_platform_combos
    left join existing_country_usage
        on country_external.geo_id = existing_country_usage.geo_id
       and date_platform_combos.date_start = existing_country_usage.date_start
       and date_platform_combos.date_end = existing_country_usage.date_end
       and date_platform_combos.platform_and_product = existing_country_usage.platform_and_product
    where existing_country_usage.geo_id is null

),

missing_us_state_usage_rows as (

    select
        us_state_external.geo_id,
        'country-state' as geography,
        date_platform_combos.date_start,
        date_platform_combos.date_end,
        date_platform_combos.platform_and_product,
        'country-state' as facet,
        cast(0 as int64) as level,
        'usage_count' as variable,
        '' as cluster_name,
        cast(0 as float64) as value
    from us_state_external
    cross join date_platform_combos
    left join existing_us_state_usage
        on us_state_external.geo_id = existing_us_state_usage.geo_id
       and date_platform_combos.date_start = existing_us_state_usage.date_start
       and date_platform_combos.date_end = existing_us_state_usage.date_end
       and date_platform_combos.platform_and_product = existing_us_state_usage.platform_and_product
    where existing_us_state_usage.geo_id is null

    union all

    select
        us_state_external.geo_id,
        'country-state' as geography,
        date_platform_combos.date_start,
        date_platform_combos.date_end,
        date_platform_combos.platform_and_product,
        'country-state' as facet,
        cast(0 as int64) as level,
        'usage_pct' as variable,
        '' as cluster_name,
        cast(0 as float64) as value
    from us_state_external
    cross join date_platform_combos
    left join existing_us_state_usage
        on us_state_external.geo_id = existing_us_state_usage.geo_id
       and date_platform_combos.date_start = existing_us_state_usage.date_start
       and date_platform_combos.date_end = existing_us_state_usage.date_end
       and date_platform_combos.platform_and_product = existing_us_state_usage.platform_and_product
    where existing_us_state_usage.geo_id is null

),

country_population_rows as (

    select
        country_external.geo_id,
        'country' as geography,
        date_platform_combos.date_start,
        date_platform_combos.date_end,
        date_platform_combos.platform_and_product,
        'country' as facet,
        cast(0 as int64) as level,
        'working_age_pop' as variable,
        '' as cluster_name,
        country_external.working_age_pop as value
    from country_external
    cross join date_platform_combos

),

us_state_population_rows as (

    select
        us_state_external.geo_id,
        'country-state' as geography,
        date_platform_combos.date_start,
        date_platform_combos.date_end,
        date_platform_combos.platform_and_product,
        'country-state' as facet,
        cast(0 as int64) as level,
        'working_age_pop' as variable,
        '' as cluster_name,
        us_state_external.working_age_pop as value
    from us_state_external
    cross join date_platform_combos

),

country_gdp_rows as (

    select
        country_external.geo_id,
        'country' as geography,
        date_platform_combos.date_start,
        date_platform_combos.date_end,
        date_platform_combos.platform_and_product,
        'country' as facet,
        cast(0 as int64) as level,
        'gdp_per_working_age_capita' as variable,
        '' as cluster_name,
        country_external.gdp_per_working_age_capita as value
    from country_external
    cross join date_platform_combos
    where country_external.gdp_per_working_age_capita is not null

),

us_state_gdp_rows as (

    select
        us_state_external.geo_id,
        'country-state' as geography,
        date_platform_combos.date_start,
        date_platform_combos.date_end,
        date_platform_combos.platform_and_product,
        'country-state' as facet,
        cast(0 as int64) as level,
        'gdp_per_working_age_capita' as variable,
        '' as cluster_name,
        us_state_external.gdp_per_working_age_capita as value
    from us_state_external
    cross join date_platform_combos
    where us_state_external.gdp_per_working_age_capita is not null

),

all_rows as (

    select * from normalized_base_rows
    union all
    select * from missing_country_usage_rows
    union all
    select * from missing_us_state_usage_rows
    union all
    select * from country_population_rows
    union all
    select * from us_state_population_rows
    union all
    select * from country_gdp_rows
    union all
    select * from us_state_gdp_rows

)

select
    all_rows.geo_id,
    coalesce(geo_names.geo_name, all_rows.geo_id) as geo_name,
    all_rows.geography,
    all_rows.date_start,
    all_rows.date_end,
    all_rows.platform_and_product,
    all_rows.facet,
    all_rows.level,
    all_rows.variable,
    all_rows.cluster_name,
    all_rows.value
from all_rows
left join geo_names
    on all_rows.geo_id = geo_names.geo_id
   and all_rows.geography = geo_names.geography
