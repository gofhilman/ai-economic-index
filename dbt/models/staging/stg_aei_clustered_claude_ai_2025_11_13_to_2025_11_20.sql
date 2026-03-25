with source as (

    select * from {{ source('clustered_dataset', 'aei_clustered_claude_ai_2025_11_13_to_2025_11_20') }}

),

renamed as (

    select
        geo_id,
        geography,
        date_start,
        date_end,
        platform_and_product,
        facet,
        level,
        variable,
        cluster_name,
        value

    from source

)

select * from renamed