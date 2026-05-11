# Demo Script

1. Show architecture and repo layout.
2. Run dbt transformations and tests.
3. Show BQML evaluation and Vertex metrics.
4. Query `ml.customer_churn_scores`.
5. Show `mart.retention_action_list`, **`mart.retention_decision_engine`** (capacity-capped cohort), and **what-if** tables.
6. Walk through **`monitoring.model_champion_selection`**, **`precision_recall_top10_daily`**, and drift / DQ outputs.
7. Walk through Executive, Retention Ops, Model Monitoring, and **What-if Simulator** dashboards.

## Screenshot Checklist

Use these screenshots for the final walkthrough:

1. BigQuery datasets: `raw`, `staging`, `mart`, `ml`, `monitoring`.
2. Raw table preview or row count: `raw.telco_customer_churn`.
3. dbt success evidence: `dbt run` / `dbt test` terminal output or built tables such as `mart.customer_health_snapshot_daily` and `ml.fct_churn_training`.
4. BQML model and scores: `ml.churn_bqml_v1` and `ml.customer_churn_scores`.
5. Monitoring evidence: `monitoring.model_metrics_history`, `monitoring.model_champion_selection`, `monitoring.precision_recall_top10_daily`, `monitoring.data_quality_results`.
6. Business output: `mart.retention_decision_engine` with churn probability, MRR at risk, ROI, and selected-for-intervention fields.
7. Looker dashboards: Executive, Retention Ops, Model Monitoring, and What-if Simulator.
8. Optional: Vertex AI Model Registry / Training Pipeline and Pub/Sub `usage-events-topic` / `raw.usage_events_stream`.
