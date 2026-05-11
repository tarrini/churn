{{ config(materialized='table') }}

with telco as (
  select
    customer_id,
    tenure,
    monthly_mrr,
    internet_service,
    mod(abs(farm_fingerprint(customer_id)), 100000000) as rng
  from {{ ref('stg_telco_customer_churn') }}
),
enriched as (
  select
    *,
    least(120, greatest(7, tenure * 4)) as window_days,
    greatest(
      1,
      least(25, cast(monthly_mrr / 5 as int64) + if(lower(coalesce(internet_service, '')) != 'no', 5, 0))
    ) as intensity
  from telco
),
day_grid as (
  select
    customer_id,
    rng,
    intensity,
    window_days,
    day_offset
  from enriched
  cross join unnest(generate_array(0, window_days - 1)) as day_offset
),
days_scored as (
  select
    customer_id,
    rng,
    intensity,
    window_days,
    day_offset,
    date_sub(current_date(), interval (window_days - 1 - day_offset) day) as usage_day,
    greatest(0, intensity + mod(rng + day_offset, 5) - 2) as daily_events
  from day_grid
),
event_counts as (
  select
    customer_id,
    rng,
    usage_day,
    daily_events,
    e_idx
  from days_scored
  cross join unnest(generate_array(1, greatest(daily_events, 0))) as e_idx
),
numbered as (
  select
    *,
    row_number() over (order by customer_id, usage_day, e_idx) as event_rn
  from event_counts
)
select
  concat('E', lpad(cast(event_rn as string), 9, '0')) as event_id,
  customer_id,
  timestamp_add(
    timestamp(usage_day),
    interval mod(rng + cast(event_rn as int64), 86400) second
  ) as event_ts,
  case mod(rng + event_rn, 4)
    when 0 then 'login'
    when 1 then 'api_call'
    when 2 then 'feature_use'
    else 'export'
  end as event_type
from numbered
