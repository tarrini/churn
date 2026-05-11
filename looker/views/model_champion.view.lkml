view: model_champion {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.monitoring.model_champion_selection` ;;

  dimension: champion_model_name { type: string sql: ${TABLE}.champion_model_name ;; }
  dimension: selected_at { type: date_time sql: ${TABLE}.selected_at ;; }

  measure: bqml_auc { type: max sql: ${TABLE}.bqml_auc ;; }
  measure: vertex_auc { type: max sql: ${TABLE}.vertex_auc ;; }
}
