view: prediction_distribution {
  sql_table_name: `{% constant BIGQUERY_PROJECT_ID %}.monitoring.prediction_distribution_history` ;;

  dimension: snapshot_date {
    type: date
    sql: ${TABLE}.snapshot_date ;;
    primary_key: yes
  }

  dimension: prob_deciles {
    type: string
    sql: ARRAY_TO_STRING(ARRAY(SELECT CAST(x AS STRING) FROM UNNEST(${TABLE}.prob_deciles) AS x), ", ") ;;
    description: "Approximate predicted_churn_prob decile boundaries"
  }

  dimension: avg_prob {
    type: number
    sql: ${TABLE}.avg_prob ;;
    value_format_name: decimal_4
  }

  dimension: std_prob {
    type: number
    sql: ${TABLE}.std_prob ;;
    value_format_name: decimal_4
  }

  dimension: scored_customers {
    type: number
    sql: ${TABLE}.scored_customers ;;
  }

  measure: average_churn_prob {
    type: max
    sql: ${TABLE}.avg_prob ;;
    value_format_name: decimal_4
  }

  measure: score_stddev {
    type: max
    sql: ${TABLE}.std_prob ;;
    value_format_name: decimal_4
  }

  measure: customers_scored {
    type: max
    sql: ${TABLE}.scored_customers ;;
  }
}
