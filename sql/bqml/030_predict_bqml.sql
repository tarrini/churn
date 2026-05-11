CREATE OR REPLACE TABLE `{{PROJECT_ID}}.ml.customer_churn_scores` AS
SELECT
  CURRENT_DATE() AS snapshot_date,
  p.customer_id,
  CAST(predicted_churned_30d_probs[OFFSET(1)].prob AS FLOAT64) AS predicted_churn_prob,
  p.monthly_mrr,
  CAST(predicted_churned_30d_probs[OFFSET(1)].prob AS FLOAT64) * p.monthly_mrr AS mrr_at_risk
FROM ML.PREDICT(
  MODEL `{{PROJECT_ID}}.ml.churn_bqml_v1`,
  (
    SELECT
      customer_id,
      monthly_mrr,
      usage_drop_pct,
      failed_invoices_90d,
      avg_resolution_hours_30d
    FROM `{{PROJECT_ID}}.ml.fct_churn_training`
  )
) p;
