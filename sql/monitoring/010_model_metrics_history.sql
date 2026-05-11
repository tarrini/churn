CREATE TABLE IF NOT EXISTS `{{PROJECT_ID}}.monitoring.model_metrics_history` (
  run_ts TIMESTAMP,
  model_name STRING,
  auc FLOAT64,
  log_loss FLOAT64,
  `precision` FLOAT64,
  `recall` FLOAT64
);

INSERT INTO `{{PROJECT_ID}}.monitoring.model_metrics_history`
(run_ts, model_name, auc, log_loss, `precision`, `recall`)
SELECT
  CURRENT_TIMESTAMP() AS run_ts,
  'churn_bqml_v1' AS model_name,
  roc_auc AS auc,
  log_loss,
  `precision`,
  `recall`
FROM ML.EVALUATE(MODEL `{{PROJECT_ID}}.ml.churn_bqml_v1`);
