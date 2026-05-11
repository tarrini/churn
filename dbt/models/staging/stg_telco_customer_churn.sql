{{ config(materialized='view') }}

-- One wide row per customer from the Kaggle CSV loaded into raw.telco_customer_churn.
select
  trim(cast(`customerID` as string)) as customer_id,
  cast(`SeniorCitizen` as int64) as senior_citizen,
  cast(`tenure` as int64) as tenure,
  safe_cast(`MonthlyCharges` as float64) as monthly_mrr,
  cast(`Contract` as string) as contract,
  cast(`InternetService` as string) as internet_service,
  lower(trim(cast(`Churn` as string))) as churn_label
from {{ source('raw', 'telco_customer_churn') }}
