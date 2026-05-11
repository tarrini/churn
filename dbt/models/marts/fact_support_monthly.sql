select
  customer_id,
  date_trunc(date(created_at), month) as support_month,
  avg(resolution_hours) as avg_resolution_hours,
  countif(priority in ('high', 'critical')) as high_priority_tickets
from {{ ref('stg_support_tickets') }}
group by 1, 2
