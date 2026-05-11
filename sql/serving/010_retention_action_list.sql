CREATE OR REPLACE TABLE `{{PROJECT_ID}}.mart.retention_action_list` AS
WITH features AS (
  SELECT
    t.customer_id,
    t.usage_drop_pct,
    t.failed_invoices_90d,
    t.avg_resolution_hours_30d
  FROM `{{PROJECT_ID}}.ml.fct_churn_training` AS t
  QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY snapshot_date DESC) = 1
)
SELECT
  s.customer_id,
  s.predicted_churn_prob,
  s.monthly_mrr,
  s.mrr_at_risk,
  CASE
    WHEN f.failed_invoices_90d >= 2 THEN 'payment_issues'
    WHEN f.avg_resolution_hours_30d > 48 THEN 'support_pain'
    WHEN f.usage_drop_pct < -0.3 THEN 'usage_drop'
    ELSE 'general_engagement_risk'
  END AS primary_risk_driver,
  CASE
    WHEN f.failed_invoices_90d >= 2 THEN 'billing_outreach'
    WHEN f.avg_resolution_hours_30d > 48 THEN 'csm_escalation'
    WHEN f.usage_drop_pct < -0.3 THEN 'product_training_session'
    ELSE 'retention_email_and_checkin'
  END AS recommended_action,
  s.predicted_churn_prob * s.monthly_mrr AS priority_score
FROM `{{PROJECT_ID}}.ml.customer_churn_scores` AS s
LEFT JOIN features AS f USING (customer_id);
