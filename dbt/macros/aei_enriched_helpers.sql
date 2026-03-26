{% macro aei_v4_filtered_geo_ids(source_relation, geography, min_usage) -%}
select distinct
    geo_id
from {{ source_relation }}
where geography = '{{ geography }}'
  and facet = '{{ geography }}'
  and variable = 'usage_count'
  and value >= {{ min_usage }}
{%- endmacro %}

{% macro aei_v4_filtered_geography_ctes(source_relation='scaffold_rows') -%}
filtered_countries as (

    {{ aei_v4_filtered_geo_ids(source_relation, 'country', 200) }}

),

filtered_us_states as (

    {{ aei_v4_filtered_geo_ids(source_relation, 'country-state', 100) }}

)
{%- endmacro %}

{% macro aei_v4_threshold_eligible_geography_condition(
    geography_column='geography',
    geo_id_column='geo_id',
    include_global=false
) -%}
(
    {%- if include_global %}
    {{ geography_column }} = 'global'
    or
    {%- endif %}
    (
        {{ geography_column }} = 'country'
        and {{ geo_id_column }} in (select geo_id from filtered_countries)
    )
    or (
        {{ geography_column }} = 'country-state'
        and {{ geo_id_column }} in (select geo_id from filtered_us_states)
    )
)
{%- endmacro %}

{% macro aei_v4_is_classified_cluster(cluster_column='cluster_name') -%}
{{ cluster_column }} not in ('none', 'not_classified')
and not regexp_contains(lower({{ cluster_column }}), r'not_classified')
{%- endmacro %}
