with source as (

    select * from {{ source('raw_dataset', 'aei_raw_claude_ai_2026_02_05_to_2026_02_12') }}

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
