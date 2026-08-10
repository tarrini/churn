view: retention_decision_engine {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.mart.retention_decision_engine` ;;

  dimension: customer_id {
    primary_key: yes
    type: string
    sql: ${TABLE}.customer_id ;;
  }
  dimension: snapshot_date { type: date sql: ${TABLE}.snapshot_date ;; }
  dimension: primary_risk_driver { type: string sql: ${TABLE}.primary_risk_driver ;; }
  dimension: base_recommended_action {
    type: string
    sql: ${TABLE}.base_recommended_action ;;
  }
  dimension: policy_action_name {
    type: string
    sql: ${TABLE}.policy_action_name ;;
  }

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
  dimension: mrr_at_risk {
    type: number
    sql: ${TABLE}.mrr_at_risk ;;
    value_format_name: usd
  }
  dimension: expected_mrr_saved {
    type: number
    sql: ${TABLE}.expected_mrr_saved ;;
    value_format_name: usd
  }
  dimension: action_cost {
    type: number
    sql: ${TABLE}.action_cost ;;
    value_format_name: usd
  }
  dimension: action_success_rate {
    type: number
    sql: ${TABLE}.action_success_rate ;;
    value_format_name: percent_1
  }
  dimension: roi_score {
    type: number
    sql: ${TABLE}.roi_score ;;
    value_format_name: decimal_2
  }
  dimension: priority_rank { type: number sql: ${TABLE}.priority_rank ;; }
  dimension: selected_for_intervention {
    type: yesno
    sql: ${TABLE}.selected_for_intervention ;;
  }

  measure: count { type: count }
  measure: total_expected_mrr_saved {
    type: sum
    sql: ${TABLE}.expected_mrr_saved ;;
    value_format_name: usd
  }
  measure: total_mrr_at_risk {
    type: sum
    sql: ${TABLE}.mrr_at_risk ;;
    value_format_name: usd
  }
  measure: average_roi_score {
    type: average
    sql: ${TABLE}.roi_score ;;
    value_format_name: decimal_2
  }
  measure: selected_customers {
    type: count
    filters: [selected_for_intervention: "yes"]
  }
}
