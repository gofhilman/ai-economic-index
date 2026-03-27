with base as (

    select
        soc_group,
        replace(replace(soc_group, ' Occupations', ''), ' Occupation', '') as soc_group_display,
        latest_vs_v1_diff_pp,
        v1_pct / 100 as v1_share,
        v2_pct / 100 as v2_share,
        v3_pct / 100 as v3_share,
        v4_pct / 100 as v4_share,
        v5_pct / 100 as v5_share
    from `ai-economic-index.output_dataset.mart_aei_occupational_trends`

)

select
    soc_group,
    soc_group_display,
    'v1' as report_version,
    date '2025-02-10' as report_release_date,
    format_date('%B %Y', date '2025-02-10') as report_release_label,
    v1_share as share,
    latest_vs_v1_diff_pp
from base

union all

select
    soc_group,
    soc_group_display,
    'v2' as report_version,
    date '2025-03-27' as report_release_date,
    format_date('%B %Y', date '2025-03-27') as report_release_label,
    v2_share as share,
    latest_vs_v1_diff_pp
from base

union all

select
    soc_group,
    soc_group_display,
    'v3' as report_version,
    date '2025-09-15' as report_release_date,
    format_date('%B %Y', date '2025-09-15') as report_release_label,
    v3_share as share,
    latest_vs_v1_diff_pp
from base

union all

select
    soc_group,
    soc_group_display,
    'v4' as report_version,
    date '2026-01-15' as report_release_date,
    format_date('%B %Y', date '2026-01-15') as report_release_label,
    v4_share as share,
    latest_vs_v1_diff_pp
from base

union all

select
    soc_group,
    soc_group_display,
    'v5' as report_version,
    date '2026-03-24' as report_release_date,
    format_date('%B %Y', date '2026-03-24') as report_release_label,
    v5_share as share,
    latest_vs_v1_diff_pp
from base
