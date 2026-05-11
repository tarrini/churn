view: dim_customer {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.mart.dim_customer` ;;
  dimension: customer_id { primary_key: yes type: string sql: ${TABLE}.customer_id ;; }
  dimension: country { type: string sql: ${TABLE}.country ;; }
  dimension: industry { type: string sql: ${TABLE}.industry ;; }
  dimension: plan_tier { type: string sql: ${TABLE}.plan_tier ;; }
}
