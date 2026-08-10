- dashboard: model_monitoring
  title: Model Monitoring Dashboard
  layout: newspaper
  preferred_viewer: dashboards-next
  description: "Champion selection, AUC history, precision/recall @ top 10%, score drift"
  elements:
  - title: Champion model
    name: champion_model
    model: churn_intelligence
    explore: model_champion
    type: single_value
    fields: [model_champion.champion_model]
    limit: 500
    row: 0
    col: 0
    width: 8
    height: 4

  - title: BQML AUC
    name: bqml_auc
    model: churn_intelligence
    explore: model_champion
    type: single_value
    fields: [model_champion.bqml_auc]
    limit: 500
    row: 0
    col: 8
    width: 8
    height: 4

  - title: Vertex AUC
    name: vertex_auc
    model: churn_intelligence
    explore: model_champion
    type: single_value
    fields: [model_champion.vertex_auc]
    limit: 500
    row: 0
    col: 16
    width: 8
    height: 4

  - title: AUC over time
    name: auc_over_time
    model: churn_intelligence
    explore: model_metrics_history
    type: looker_line
    fields: [model_metrics_history.run_ts, model_metrics_history.model_name, model_metrics_history.auc]
    pivots: [model_metrics_history.model_name]
    sorts: [model_metrics_history.run_ts]
    limit: 500
    listen:
      Model Name: model_metrics_history.model_name
    row: 4
    col: 0
    width: 12
    height: 8

  - title: Precision@10 / Recall@10
    name: precision_recall_top10
    model: churn_intelligence
    explore: precision_recall_top10
    type: looker_line
    fields:
    - precision_recall_top10.snapshot_date
    - precision_recall_top10.precision_at_10
    - precision_recall_top10.recall_at_10
    sorts: [precision_recall_top10.snapshot_date]
    limit: 500
    row: 4
    col: 12
    width: 12
    height: 8

  - title: Score distribution (avg / stddev)
    name: score_drift
    model: churn_intelligence
    explore: prediction_distribution
    type: looker_line
    fields:
    - prediction_distribution.snapshot_date
    - prediction_distribution.average_churn_prob
    - prediction_distribution.score_stddev
    sorts: [prediction_distribution.snapshot_date]
    limit: 500
    row: 12
    col: 0
    width: 24
    height: 8

  filters:
  - name: Model Name
    title: Model Name
    type: field_filter
    default_value: ""
    allow_multiple_values: true
    required: false
    ui_config:
      type: checkboxes
      display: popover
    model: churn_intelligence
    explore: model_metrics_history
    field: model_metrics_history.model_name
