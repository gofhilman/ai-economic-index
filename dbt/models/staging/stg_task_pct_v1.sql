with source as (

    select * from {{ source('raw_dataset', 'task_pct_v1') }}

),

renamed as (

    select
        task_name,
        pct

    from source

)

select * from renamed