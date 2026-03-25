with source as (

    select * from {{ source('external_dataset', 'working_age_pop_2024_us_state') }}

),

renamed as (

    select
        state,
        working_age_pop,
        state_code

    from source

)

select * from renamed