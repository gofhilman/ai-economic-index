select
    report_version,
    sum(pct) as total_pct
from {{ ref('int_aei_task_shares_by_version') }}
where report_version in ('v1', 'v2')
group by 1
having sum(pct) < 80 or sum(pct) > 120
