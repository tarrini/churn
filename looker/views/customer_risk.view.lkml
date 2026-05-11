view: customer_risk {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.ml.customer_churn_scores` ;;

  dimension: customer_id { primary_key: yes type: string sql: ${TABLE}.customer_id ;; }
  dimension: snapshot_date { type: date sql: ${TABLE}.snapshot_date ;; }
  dimension: predicted_churn_prob { type: number sql: ${TABLE}.predicted_churn_prob ;; }
  dimension: monthly_mrr { type: number sql: ${TABLE}.monthly_mrr ;; }

  measure: high_risk_customers {
    type: count
    filters: [predicted_churn_prob: ">=0.7"]
  }
  measure: mrr_at_risk { type: sum sql: ${TABLE}.mrr_at_risk ;; }
}
