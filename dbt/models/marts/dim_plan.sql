select distinct
  plan_tier,
  case
    when plan_tier = 'basic' then 1
    when plan_tier = 'pro' then 2
    when plan_tier = 'enterprise' then 3
    else 0
  end as plan_rank
from {{ ref('stg_customers') }}
