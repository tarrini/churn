CREATE OR REPLACE TABLE `{{PROJECT_ID}}.monitoring.precision_recall_top10_daily` AS
WITH latest_features AS (
  SELECT
    customer_id,
    churned_30d
  FROM `{{PROJECT_ID}}.ml.fct_churn_training`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY snapshot_date DESC) = 1
),
scored AS (
  SELECT
    s.customer_id,
    s.predicted_churn_prob,
    lf.churned_30d
  FROM `{{PROJECT_ID}}.ml.customer_churn_scores` AS s
  INNER JOIN latest_features AS lf USING (customer_id)
),
ranked AS (
  SELECT
    *,
    NTILE(10) OVER (ORDER BY predicted_churn_prob DESC) AS risk_decile
  FROM scored
),
agg AS (
  SELECT
    COUNT(*) AS scored_customers,
    COUNTIF(risk_decile = 1) AS customers_in_top10pct,
    COUNTIF(risk_decile = 1 AND churned_30d = 1) AS true_churners_in_top10pct,
    SUM(churned_30d) AS all_true_churners
  FROM ranked
)
SELECT
  CURRENT_DATE() AS snapshot_date,
  scored_customers,
  customers_in_top10pct,
  true_churners_in_top10pct,
  all_true_churners,
  SAFE_DIVIDE(true_churners_in_top10pct, NULLIF(customers_in_top10pct, 0)) AS precision_at_10,
  SAFE_DIVIDE(true_churners_in_top10pct, NULLIF(all_true_churners, 0)) AS recall_at_10
FROM agg;
