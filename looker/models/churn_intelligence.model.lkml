# Must match the exact name of your BigQuery connection in Looker Admin → Connections.
connection: "bigquery_connection"

include: "/constants.lkml"
include: "/views/*.view.lkml"
explore: customer_risk {
  join: dim_customer {
    sql_on: ${customer_risk.customer_id} = ${dim_customer.customer_id} ;;
    relationship: many_to_one
    type: left_outer
  }
}

explore: retention_decision_engine {
  label: "Retention Decision Engine"
  join: dim_customer {
    sql_on: ${retention_decision_engine.customer_id} = ${dim_customer.customer_id} ;;
    relationship: many_to_one
    type: left_outer
  }
}

explore: retention_what_if {
  label: "What-if (capacity & threshold)"
}

explore: retention_marginal_gain {
  label: "Capacity marginal gain"
}

explore: model_champion {
  label: "Model champion (BQML vs Vertex)"
}

explore: precision_recall_top10 {
  label: "Precision / recall @ top decile"
}

explore: model_metrics_history {
  label: "Model metrics history (AUC over time)"
}
