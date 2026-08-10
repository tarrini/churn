view: customer_risk {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.ml.customer_churn_scores` ;;

  dimension: customer_id { primary_key: yes type: string sql: ${TABLE}.customer_id ;; }
  dimension: snapshot_date { type: date sql: ${TABLE}.snapshot_date ;; }
  dimension: predicted_churn_prob {
    type: number
    sql: ${TABLE}.predicted_churn_prob ;;
    value_format_name: percent_1
  }
  dimension: monthly_mrr {
    type: number
    sql: ${TABLE}.monthly_mrr ;;
    value_format_name: usd
  }
  dimension: mrr_at_risk_amount {
    type: number
    sql: ${TABLE}.mrr_at_risk ;;
    value_format_name: usd
  }

  measure: customer_count { type: count }
  measure: high_risk_customers {
    type: count
    filters: [predicted_churn_prob: ">=0.7"]
  }
  measure: mrr_at_risk {
    type: sum
    sql: ${TABLE}.mrr_at_risk ;;
    value_format_name: usd
  }
  measure: average_churn_prob {
    type: average
    sql: ${TABLE}.predicted_churn_prob ;;
    value_format_name: percent_1
  }
}
