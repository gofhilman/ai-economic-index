with source as (

    select * from {{ source('external_dataset', 'soc_structure') }}

),

renamed as (

    select
        major_group,
        minor_group,
        broad_occupation,
        detailed_occupation,
        detailed_o_net_soc,
        soc_or_o_net_soc_2019_title,
        soc_major_group

    from source

)

select * from renamed