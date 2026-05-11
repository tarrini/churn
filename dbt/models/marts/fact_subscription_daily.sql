select
  customer_id,
  status,
  monthly_mrr,
  start_date,
  cancel_date,
  current_date() as snapshot_date
from {{ ref('stg_subscriptions') }}
