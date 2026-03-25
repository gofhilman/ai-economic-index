with source as (

    select * from {{ source('raw_dataset', 'automation_vs_augmentation_v1') }}

),

renamed as (

    select
        interaction_type,
        pct

    from source

)

select * from renamed