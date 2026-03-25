with source as (

    select * from {{ source('external_dataset', 'working_age_pop_2024_country') }}

),

renamed as (

    select
        iso_alpha_3,
        year,
        working_age_pop,
        country_code,
        country_name

    from source

)

select * from renamed