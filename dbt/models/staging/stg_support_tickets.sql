{{ config(materialized='table') }}

with telco as (select * from {{ ref('stg_telco_customer_churn') }}),
base as (
  select
    customer_id,
    tenure,
    churn_label,
    mod(abs(farm_fingerprint(customer_id)), 100000000) as rng,
    if(churn_label in ('yes', 'true', '1'), true, false) as is_churn
  from telco
),
nt as (
  select
    *,
    least(12, cast(floor(tenure / 6) as int64) + if(is_churn, 2, 0)) as n_tickets
  from base
),
expanded as (
  select
    customer_id,
    tenure,
    churn_label,
    rng,
    ti
  from nt
  cross join unnest(generate_array(1, greatest(n_tickets, 0))) as ti
),
numbered as (
  select
    *,
    row_number() over (order by customer_id, ti) as rn
  from expanded
)
select
  concat('T', lpad(cast(rn as string), 7, '0')) as ticket_id,
  customer_id,
  timestamp_add(
    timestamp(date_sub(current_date(), interval tenure month)),
    interval (mod(rng + ti * 11, greatest(tenure * 10, 1))) day
  ) as created_at,
  case mod(rng + ti, 4)
    when 0 then 'low'
    when 1 then 'medium'
    when 2 then 'high'
    else 'critical'
  end as priority,
  round(4.0 + mod(rng, 80) + ti * 3.0, 2) as resolution_hours
from numbered
