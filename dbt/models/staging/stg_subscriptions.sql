select
  concat(
    'S',
    lpad(cast(mod(abs(farm_fingerprint(concat(customer_id, ':sub'))), 100000000) as string), 8, '0')
  ) as subscription_id,
  customer_id,
  if(churn_label in ('yes', 'true', '1'), 'canceled', 'active') as status,
  monthly_mrr,
  date(date_sub(current_date(), interval tenure month)) as start_date,
  if(
    churn_label in ('yes', 'true', '1'),
    date_add(date(date_sub(current_date(), interval tenure month)), interval tenure month),
    cast(null as date)
  ) as cancel_date
from {{ ref('stg_telco_customer_churn') }}
