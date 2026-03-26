select
    report_version,
    sum(pct) as total_pct
from {{ ref('int_aei_task_shares_by_version') }}
where report_version in ('v3', 'v4', 'v5')
group by 1
having abs(sum(pct) - 100) > 0.001
