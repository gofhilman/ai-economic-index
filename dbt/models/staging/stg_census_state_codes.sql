with source as (

    select * from {{ source('external_dataset', 'census_state_codes') }}

),

renamed as (

    select
        state,
        stusab,
        state_name,
        statens

    from source

)

select * from renamed