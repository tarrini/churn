CREATE OR REPLACE TABLE `{{PROJECT_ID}}.monitoring.prediction_distribution_history` AS
SELECT
  CURRENT_DATE() AS snapshot_date,
  APPROX_QUANTILES(predicted_churn_prob, 10) AS prob_deciles,
  AVG(predicted_churn_prob) AS avg_prob,
  STDDEV(predicted_churn_prob) AS std_prob,
  COUNT(*) AS scored_customers
FROM `{{PROJECT_ID}}.ml.customer_churn_scores`;
