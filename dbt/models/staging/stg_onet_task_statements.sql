with source as (

    select * from {{ source('external_dataset', 'onet_task_statements') }}

),

renamed as (

    select
        o_net_soc_code,
        title,
        task_id,
        task,
        task_type,
        incumbents_responding,
        date,
        domain_source,
        soc_major_group

    from source

)

select * from renamed