view: model_metrics_history {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.monitoring.model_metrics_history` ;;

  dimension: run_ts { type: date_time sql: ${TABLE}.run_ts ;; }
  dimension: model_name { type: string sql: ${TABLE}.model_name ;; }

  measure: auc {
    type: max
    sql: ${TABLE}.auc ;;
    value_format_name: decimal_4
  }
  measure: log_loss {
    type: max
    sql: ${TABLE}.log_loss ;;
    value_format_name: decimal_4
  }
}
