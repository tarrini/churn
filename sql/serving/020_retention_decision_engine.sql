CREATE OR REPLACE TABLE `{{PROJECT_ID}}.mart.retention_decision_engine` AS
WITH base AS (
  SELECT
    s.snapshot_date,
    s.customer_id,
    s.predicted_churn_prob,
    s.monthly_mrr,
    s.mrr_at_risk,
    r.primary_risk_driver,
    r.recommended_action
  FROM `{{PROJECT_ID}}.ml.customer_churn_scores` AS s
  LEFT JOIN `{{PROJECT_ID}}.mart.retention_action_list` AS r USING (customer_id)
),
policy AS (
  SELECT 'payment_issues' AS driver, 'billing_outreach' AS action_name, 8.0 AS action_cost, 0.18 AS success_rate
  UNION ALL
  SELECT 'usage_drop', 'product_training_call', 25.0, 0.28
  UNION ALL
  SELECT 'support_pain', 'priority_support_callback', 30.0, 0.32
  UNION ALL
  SELECT 'general_engagement_risk', 'csm_checkin_email', 2.0, 0.07
),
scored AS (
  SELECT
    b.snapshot_date,
    b.customer_id,
    b.predicted_churn_prob,
    b.monthly_mrr,
    b.mrr_at_risk,
    b.primary_risk_driver,
    b.recommended_action,
    COALESCE(p.action_name, 'csm_checkin_email') AS policy_action_name,
    COALESCE(p.action_cost, 2.0) AS action_cost,
    COALESCE(p.success_rate, 0.07) AS action_success_rate,
    b.predicted_churn_prob * b.monthly_mrr * COALESCE(p.success_rate, 0.07) AS expected_mrr_saved
  FROM base AS b
  LEFT JOIN policy AS p ON b.primary_risk_driver = p.driver
),
ranked AS (
  SELECT
    *,
    (expected_mrr_saved - action_cost) AS roi_score,
    ROW_NUMBER() OVER (
      PARTITION BY snapshot_date ORDER BY (expected_mrr_saved - action_cost) DESC
    ) AS priority_rank
  FROM scored
)
SELECT
  snapshot_date,
  customer_id,
  predicted_churn_prob,
  monthly_mrr,
  mrr_at_risk,
  primary_risk_driver,
  recommended_action AS base_recommended_action,
  policy_action_name,
  action_cost,
  action_success_rate,
  expected_mrr_saved,
  roi_score,
  priority_rank,
  priority_rank <= 200 AS selected_for_intervention
FROM ranked;
