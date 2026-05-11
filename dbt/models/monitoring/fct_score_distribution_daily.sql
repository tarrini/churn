select
  snapshot_date,
  count(*) as scored_customers,
  avg(predicted_churn_prob) as avg_score,
  stddev(predicted_churn_prob) as std_score
from `{{ env_var('GCP_PROJECT_ID') }}.ml.customer_churn_scores`
group by 1
