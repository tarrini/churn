{{ config(materialized='table') }}

with telco as (select * from {{ ref('stg_telco_customer_churn') }}),
base as (
  select
    customer_id,
    tenure,
    monthly_mrr as mrr,
    mod(abs(farm_fingerprint(customer_id)), 100000000) as rng,
    mod(abs(farm_fingerprint(concat(customer_id, ':inv'))), 100000000) as inv_mix
  from telco
),
expanded as (
  select
    base.customer_id,
    base.mrr,
    base.rng,
    base.inv_mix,
    mo,
    date_add(
      date(date_sub(current_date(), interval base.tenure month)),
      interval mo month
    ) as invoice_date
  from base
  cross join unnest(
    if(base.tenure <= 0, [], generate_array(0, base.tenure - 1))
  ) as mo
),
numbered as (
  select
    *,
    row_number() over (order by customer_id, invoice_date) as rn
  from expanded
)
select
  concat('I', lpad(cast(rn as string), 7, '0')) as invoice_id,
  customer_id,
  invoice_date,
  cast(mrr as float64) as amount,
  if(mod(rng + mo + inv_mix, 17) = 0, 'failed', 'paid') as status
from numbered
