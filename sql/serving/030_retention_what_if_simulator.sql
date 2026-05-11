CREATE OR REPLACE TABLE `{{PROJECT_ID}}.mart.retention_what_if_simulator` AS
WITH base AS (
  SELECT
    snapshot_date,
    customer_id,
    predicted_churn_prob,
    monthly_mrr,
    mrr_at_risk,
    expected_mrr_saved,
    action_cost,
    roi_score
  FROM `{{PROJECT_ID}}.mart.retention_decision_engine`
),
scenarios AS (
  SELECT 100 AS capacity_limit, 0.60 AS risk_threshold
  UNION ALL SELECT 100, 0.70
  UNION ALL SELECT 100, 0.80
  UNION ALL SELECT 200, 0.60
  UNION ALL SELECT 200, 0.70
  UNION ALL SELECT 200, 0.80
  UNION ALL SELECT 300, 0.60
  UNION ALL SELECT 300, 0.70
  UNION ALL SELECT 300, 0.80
  UNION ALL SELECT 500, 0.60
  UNION ALL SELECT 500, 0.70
  UNION ALL SELECT 500, 0.80
),
eligible AS (
  SELECT
    b.snapshot_date,
    s.capacity_limit,
    s.risk_threshold,
    b.customer_id,
    b.predicted_churn_prob,
    b.monthly_mrr,
    b.mrr_at_risk,
    b.expected_mrr_saved,
    b.action_cost,
    b.roi_score,
    ROW_NUMBER() OVER (
      PARTITION BY b.snapshot_date, s.capacity_limit,
        CAST(ROUND(s.risk_threshold * 10000) AS INT64)
      ORDER BY b.roi_score DESC
    ) AS scenario_rank
  FROM base AS b
  CROSS JOIN scenarios AS s
  WHERE b.predicted_churn_prob >= s.risk_threshold
),
selected AS (
  SELECT *
  FROM eligible
  WHERE scenario_rank <= capacity_limit
)
SELECT
  snapshot_date,
  CONCAT(
    'cap_',
    CAST(capacity_limit AS STRING),
    '_thr_',
    REPLACE(CAST(risk_threshold AS STRING), '.', '')
  ) AS scenario_id,
  capacity_limit,
  risk_threshold,
  COUNT(*) AS selected_customers,
  SUM(mrr_at_risk) AS total_mrr_at_risk_selected,
  SUM(expected_mrr_saved) AS total_expected_mrr_saved,
  SUM(action_cost) AS total_action_cost,
  SUM(expected_mrr_saved) - SUM(action_cost) AS net_expected_value,
  SAFE_DIVIDE(
    SUM(expected_mrr_saved) - SUM(action_cost),
    NULLIF(COUNT(*), 0)
  ) AS avg_roi_per_customer
FROM selected
GROUP BY 1, 2, 3, 4;
