with scaffold_rows as (

    select *
    from {{ ref('int_aei_enriched_v4_scaffold_rows') }}

),

{{ aei_v4_filtered_geography_ctes('scaffold_rows') }},

collaboration_count_rows as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        cluster_name,
        value,
        case
            when regexp_contains(lower(replace(replace(cluster_name, '_', ' '), '-', ' ')), r'validation')
                then 'augmentation'
            when regexp_contains(lower(replace(replace(cluster_name, '_', ' '), '-', ' ')), r'task iteration')
                then 'augmentation'
            when regexp_contains(lower(replace(replace(cluster_name, '_', ' '), '-', ' ')), r'learning')
                then 'augmentation'
            when regexp_contains(lower(replace(replace(cluster_name, '_', ' '), '-', ' ')), r'directive')
                then 'automation'
            when regexp_contains(lower(replace(replace(cluster_name, '_', ' '), '-', ' ')), r'feedback loop')
                then 'automation'
        end as category
    from scaffold_rows
    where facet = 'collaboration'
      and variable = 'collaboration_count'

),

eligible_collaboration_rows as (

    select *
    from collaboration_count_rows
    where category is not null
      and {{ aei_v4_threshold_eligible_geography_condition(include_global=true) }}

),

collaboration_totals as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        sum(case when category = 'automation' then value else 0 end) as automation_total,
        sum(case when category = 'augmentation' then value else 0 end) as augmentation_total
    from eligible_collaboration_rows
    group by 1, 2, 3, 4, 5, 6

),

automation_augmentation_rows as (

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        'collaboration_automation_augmentation' as facet,
        cast(0 as int64) as level,
        'automation_pct' as variable,
        'automation' as cluster_name,
        safe_divide(automation_total * 100, automation_total + augmentation_total) as value
    from collaboration_totals
    where automation_total + augmentation_total > 0

    union all

    select
        geo_id,
        geo_name,
        geography,
        date_start,
        date_end,
        platform_and_product,
        'collaboration_automation_augmentation' as facet,
        cast(0 as int64) as level,
        'augmentation_pct' as variable,
        'augmentation' as cluster_name,
        safe_divide(augmentation_total * 100, automation_total + augmentation_total) as value
    from collaboration_totals
    where automation_total + augmentation_total > 0

)

select * from automation_augmentation_rows
