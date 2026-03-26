{% macro aei_report_versions() -%}
    {{ return(['v1', 'v2', 'v3', 'v4', 'v5']) }}
{%- endmacro %}

{% macro aei_report_release_date_literal(report_version) -%}
    {%- if report_version == 'v1' -%}
        date '2025-02-10'
    {%- elif report_version == 'v2' -%}
        date '2025-03-27'
    {%- elif report_version == 'v3' -%}
        date '2025-09-15'
    {%- elif report_version == 'v4' -%}
        date '2026-01-15'
    {%- elif report_version == 'v5' -%}
        date '2026-03-24'
    {%- else -%}
        {{ exceptions.raise_compiler_error('Unsupported AEI report version: ' ~ report_version) }}
    {%- endif -%}
{%- endmacro %}

{% macro aei_normalize_text(column_name) -%}
lower(trim({{ column_name }}))
{%- endmacro %}

{% macro aei_normalize_identifier(column_name) -%}
replace({{ aei_normalize_text(column_name) }}, ' ', '_')
{%- endmacro %}

{% macro aei_version_pct_columns(version_column='report_version', value_column='pct') -%}
{%- for report_version in aei_report_versions() %}
sum(
    case when {{ version_column }} = '{{ report_version }}' then {{ value_column }} else 0 end
) as {{ report_version }}_pct{%- if not loop.last %},
        {% endif -%}
{%- endfor %}
{%- endmacro %}
