CREATE OR REPLACE TABLE `{{PROJECT_ID}}.monitoring.data_quality_results` AS
WITH checks AS (
  SELECT 'dim_customer_null_customer_id' AS check_name,
         COUNTIF(customer_id IS NULL) AS failed_rows
  FROM `{{PROJECT_ID}}.mart.dim_customer`
  UNION ALL
  SELECT 'fct_churn_training_null_label',
         COUNTIF(churned_30d IS NULL)
  FROM `{{PROJECT_ID}}.ml.fct_churn_training`
  UNION ALL
  SELECT 'customer_churn_scores_null_prob',
         COUNTIF(predicted_churn_prob IS NULL)
  FROM `{{PROJECT_ID}}.ml.customer_churn_scores`
  UNION ALL
  SELECT 'retention_decision_engine_null_roi',
         COUNTIF(roi_score IS NULL)
  FROM `{{PROJECT_ID}}.mart.retention_decision_engine`
  UNION ALL
  SELECT 'retention_what_if_simulator_empty',
         CASE WHEN COUNT(*) = 0 THEN 1 ELSE 0 END
  FROM `{{PROJECT_ID}}.mart.retention_what_if_simulator`
)
SELECT
  CURRENT_TIMESTAMP() AS checked_at,
  check_name,
  failed_rows,
  failed_rows = 0 AS passed
FROM checks;
