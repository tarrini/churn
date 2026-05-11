view: precision_recall_top10 {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.monitoring.precision_recall_top10_daily` ;;

  dimension: snapshot_date { type: date sql: ${TABLE}.snapshot_date ;; primary_key: yes }

  dimension: scored_customers { type: number sql: ${TABLE}.scored_customers ;; hidden: yes }
  dimension: customers_in_top10pct { type: number sql: ${TABLE}.customers_in_top10pct ;; hidden: yes }
  dimension: true_churners_in_top10pct { type: number sql: ${TABLE}.true_churners_in_top10pct ;; hidden: yes }
  dimension: all_true_churners { type: number sql: ${TABLE}.all_true_churners ;; hidden: yes }

  measure: precision_at_10 {
    type: max
    sql: ${TABLE}.precision_at_10 ;;
    value_format_name: decimal_4
  }
  measure: recall_at_10 {
    type: max
    sql: ${TABLE}.recall_at_10 ;;
    value_format_name: decimal_4
  }
}
