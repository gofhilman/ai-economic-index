with source as (

    select * from {{ source('external_dataset', 'gdp_2024_us_state') }}

),

renamed as (

    select
        state_code,
        state_name,
        gdp_total,
        gdp_millions,
        year

    from source

)

select * from renamed