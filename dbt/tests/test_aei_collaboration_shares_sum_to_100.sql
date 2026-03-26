select
    report_version,
    sum(pct) as total_pct
from {{ ref('int_aei_collaboration_shares_by_version') }}
group by 1
having abs(sum(pct) - 100) > 0.001
