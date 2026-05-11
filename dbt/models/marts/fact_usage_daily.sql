select
  customer_id,
  date(event_ts) as usage_date,
  count(*) as usage_events
from {{ ref('stg_usage_events') }}
group by 1, 2
