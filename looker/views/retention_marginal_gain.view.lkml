view: retention_marginal_gain {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.mart.retention_capacity_marginal_gain` ;;

  dimension: snapshot_date { type: date sql: ${TABLE}.snapshot_date ;; }
  dimension: risk_threshold { type: number sql: ${TABLE}.risk_threshold ;; }
  dimension: base_capacity { type: number sql: ${TABLE}.base_capacity ;; }
  dimension: new_capacity { type: number sql: ${TABLE}.new_capacity ;; }

  measure: marginal_net_value { type: sum sql: ${TABLE}.marginal_net_value ;; }
}
