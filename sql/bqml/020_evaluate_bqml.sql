CREATE OR REPLACE TABLE `{{PROJECT_ID}}.monitoring.bqml_eval_latest` AS
SELECT *
FROM ML.EVALUATE(MODEL `{{PROJECT_ID}}.ml.churn_bqml_v1`);
