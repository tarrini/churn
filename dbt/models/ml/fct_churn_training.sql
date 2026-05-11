with base as (
  select
    h.snapshot_date,
    h.customer_id,
    h.monthly_mrr,
    h.usage_drop_pct,
    h.failed_invoices_90d,
    h.avg_resolution_hours_30d,
    s.start_date,
    s.status,
    c.churn_label
  from {{ ref('customer_health_snapshot_daily') }} h
  join {{ ref('stg_subscriptions') }} s using (customer_id)
  join {{ ref('stg_telco_customer_churn') }} c using (customer_id)
),
labeled as (
  select
    *,
    -- Kaggle landing is one row per customer with Churn yes/no; active rows have null
    -- cancel_date in stg_subscriptions, so a forward-looking cancel window never yields 1.
    case
      when churn_label in ('yes', 'true', '1') then 1
      else 0
    end as churned_30d,
    date_diff(snapshot_date, start_date, day) as tenure_days
  from base
)
select
  snapshot_date,
  customer_id,
  monthly_mrr,
  coalesce(usage_drop_pct, 0) as usage_drop_pct,
  failed_invoices_90d,
  avg_resolution_hours_30d,
  churned_30d
from labeled
where tenure_days >= 14
