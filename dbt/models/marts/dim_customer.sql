select
  customer_id,
  created_at,
  country,
  industry,
  company_size,
  plan_tier
from {{ ref('stg_customers') }}
