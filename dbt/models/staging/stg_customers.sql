select
  customer_id,
  timestamp(date_sub(current_date(), interval tenure month)) as created_at,
  'US' as country,
  'Telecom' as industry,
  if(senior_citizen = 1, 50, 100) as company_size,
  case
    when lower(contract) like '%two year%' then 'enterprise'
    when lower(contract) like '%one year%' then 'pro'
    else 'basic'
  end as plan_tier
from {{ ref('stg_telco_customer_churn') }}
