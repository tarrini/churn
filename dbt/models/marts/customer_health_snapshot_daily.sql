with latest_usage as (
  select customer_id, sum(usage_events) as usage_30d
  from {{ ref('fact_usage_daily') }}
  where usage_date >= date_sub(current_date(), interval 30 day)
  group by 1
),
prev_usage as (
  select customer_id, sum(usage_events) as usage_prev_30d
  from {{ ref('fact_usage_daily') }}
  where usage_date between date_sub(current_date(), interval 60 day) and date_sub(current_date(), interval 31 day)
  group by 1
),
billing as (
  select customer_id, sum(failed_invoices) as failed_invoices_90d
  from {{ ref('fact_billing_monthly') }}
  where invoice_month >= date_sub(date_trunc(current_date(), month), interval 3 month)
  group by 1
),
support as (
  select customer_id, avg(avg_resolution_hours) as avg_resolution_hours_30d
  from {{ ref('fact_support_monthly') }}
  where support_month >= date_sub(date_trunc(current_date(), month), interval 1 month)
  group by 1
)
select
  s.customer_id,
  current_date() as snapshot_date,
  s.monthly_mrr,
  safe_divide(lu.usage_30d - pu.usage_prev_30d, nullif(pu.usage_prev_30d, 0)) as usage_drop_pct,
  coalesce(b.failed_invoices_90d, 0) as failed_invoices_90d,
  coalesce(sp.avg_resolution_hours_30d, 0) as avg_resolution_hours_30d
from {{ ref('stg_subscriptions') }} s
left join latest_usage lu using (customer_id)
left join prev_usage pu using (customer_id)
left join billing b using (customer_id)
left join support sp using (customer_id)
