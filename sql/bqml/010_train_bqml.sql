CREATE OR REPLACE MODEL `{{PROJECT_ID}}.ml.churn_bqml_v1`
OPTIONS(
  model_type='LOGISTIC_REG',
  input_label_cols=['churned_30d']
) AS
SELECT
  monthly_mrr,
  usage_drop_pct,
  failed_invoices_90d,
  avg_resolution_hours_30d,
  churned_30d
FROM `{{PROJECT_ID}}.ml.fct_churn_training`;
