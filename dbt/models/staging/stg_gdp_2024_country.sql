with source as (

    select * from {{ source('external_dataset', 'gdp_2024_country') }}

),

renamed as (

    select
        iso_alpha_3,
        gdp_total,
        year

    from source

)

select * from renamed