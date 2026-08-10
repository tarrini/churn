# Must match Looker Admin → Connections exactly.
# Create a BigQuery connection named "churn_bigquery" (or change this string to match yours).
connection: "churn_bigquery"

include: "/constants.lkml"
include: "/views/*.view.lkml"
include: "/dashboards/*.dashboard.lookml"

datagroup: churn_daily {
  max_cache_age: "24 hours"
}

persist_with: churn_daily

explore: customer_risk {
  label: "Customer Risk (scores)"
  description: "Churn probabilities and MRR at risk from ml.customer_churn_scores"
  join: dim_customer {
    sql_on: ${customer_risk.customer_id} = ${dim_customer.customer_id} ;;
    relationship: many_to_one
    type: left_outer
  }
}

explore: retention_decision_engine {
  label: "Retention Decision Engine"
  description: "ROI-ranked intervention list; filter selected_for_intervention for the top 200"
  join: dim_customer {
    sql_on: ${retention_decision_engine.customer_id} = ${dim_customer.customer_id} ;;
    relationship: many_to_one
    type: left_outer
  }
}

explore: retention_what_if {
  label: "What-if (capacity & threshold)"
  description: "Scenario grid of capacity × risk threshold from retention_what_if_simulator"
}

explore: retention_marginal_gain {
  label: "Capacity marginal gain"
  description: "Extra net value when increasing contact capacity"
}

explore: model_champion {
  label: "Model champion (BQML vs Vertex)"
  description: "Latest champion selection by AUC"
}

explore: precision_recall_top10 {
  label: "Precision / recall @ top decile"
  description: "Precision@10 and recall@10 for the top 10% risk cohort"
}

explore: model_metrics_history {
  label: "Model metrics history (AUC over time)"
  description: "Appended BQML/Vertex evaluation metrics over time"
}

explore: prediction_distribution {
  label: "Score distribution (drift)"
  description: "Predicted churn score distribution snapshot for drift monitoring"
}
