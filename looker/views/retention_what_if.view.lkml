view: retention_what_if {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.mart.retention_what_if_simulator` ;;

  dimension: scenario_id { type: string sql: ${TABLE}.scenario_id ;; }
  dimension: snapshot_date { type: date sql: ${TABLE}.snapshot_date ;; }
  dimension: capacity_limit { type: number sql: ${TABLE}.capacity_limit ;; }
  dimension: risk_threshold { type: number sql: ${TABLE}.risk_threshold ;; }

  measure: selected_customers { type: sum sql: ${TABLE}.selected_customers ;; }
  measure: net_expected_value { type: sum sql: ${TABLE}.net_expected_value ;; }
  measure: total_expected_mrr_saved { type: sum sql: ${TABLE}.total_expected_mrr_saved ;; }
  measure: total_action_cost { type: sum sql: ${TABLE}.total_action_cost ;; }
}
