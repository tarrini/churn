CREATE OR REPLACE TABLE `{{PROJECT_ID}}.monitoring.model_champion_selection` AS
WITH latest AS (
  SELECT
    *
  FROM `{{PROJECT_ID}}.monitoring.model_metrics_history`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY model_name ORDER BY run_ts DESC) = 1
),
bqml AS (
  SELECT * FROM latest WHERE model_name = 'churn_bqml_v1'
),
vertex AS (
  SELECT * FROM latest WHERE model_name = 'churn_vertex_v1'
)
SELECT
  CURRENT_TIMESTAMP() AS selected_at,
  CASE
    WHEN vertex.model_name IS NULL THEN bqml.model_name
    WHEN bqml.model_name IS NULL THEN vertex.model_name
    WHEN vertex.auc > bqml.auc THEN vertex.model_name
    ELSE bqml.model_name
  END AS champion_model_name,
  bqml.auc AS bqml_auc,
  vertex.auc AS vertex_auc,
  bqml.log_loss AS bqml_log_loss,
  vertex.log_loss AS vertex_log_loss,
  bqml.`precision` AS bqml_precision,
  vertex.`precision` AS vertex_precision,
  bqml.`recall` AS bqml_recall,
  vertex.`recall` AS vertex_recall
FROM bqml
FULL OUTER JOIN vertex ON TRUE;
