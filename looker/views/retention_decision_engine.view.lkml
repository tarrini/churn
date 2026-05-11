view: retention_decision_engine {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.mart.retention_decision_engine` ;;

  dimension: customer_id { type: string sql: ${TABLE}.customer_id ;; }
  dimension: snapshot_date { type: date sql: ${TABLE}.snapshot_date ;; }
  dimension: primary_risk_driver { type: string sql: ${TABLE}.primary_risk_driver ;; }

  dimension: predicted_churn_prob { type: number sql: ${TABLE}.predicted_churn_prob ;; }
  dimension: monthly_mrr { type: number sql: ${TABLE}.monthly_mrr ;; }
  dimension: expected_mrr_saved { type: number sql: ${TABLE}.expected_mrr_saved ;; }
  dimension: action_cost { type: number sql: ${TABLE}.action_cost ;; }
  dimension: roi_score { type: number sql: ${TABLE}.roi_score ;; }
  dimension: priority_rank { type: number sql: ${TABLE}.priority_rank ;; }
  dimension: selected_for_intervention { type: yesno sql: ${TABLE}.selected_for_intervention ;; }

  measure: count { type: count }
  measure: total_expected_mrr_saved { type: sum sql: ${TABLE}.expected_mrr_saved ;; }
  measure: total_mrr_at_risk { type: sum sql: ${TABLE}.mrr_at_risk ;; }
}
