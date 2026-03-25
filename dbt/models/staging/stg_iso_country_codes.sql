with source as (

    select * from {{ source('external_dataset', 'iso_country_codes') }}

),

renamed as (

    select
        iso_alpha_2,
        iso_alpha_3,
        country_name

    from source

)

select * from renamed