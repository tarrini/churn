# Customer Churn & Revenue Risk Intelligence Platform

## Problem Statement
Retention teams often identify churn too late and cannot clearly quantify revenue exposure.

## Business Value
This project predicts churn risk, estimates `mrr_at_risk`, and creates actionable retention worklists so teams can intervene early.

### Project Outcomes
1. Built an **end-to-end churn analytics platform** with **batch** ingestion from Kaggle CSV into BigQuery and optional **streaming** ingestion from Pub/Sub into `raw.usage_events_stream`.
2. Modeled customer, subscription, billing, support, and usage data into analytics-ready dbt marts.
3. Trained a **BigQuery ML baseline** and optional **Vertex AI challenger** for churn prediction.
4. Built monitoring outputs for model metrics, score drift, champion selection, precision/recall, and data quality.
5. Built serving tables for retention prioritization, ROI-based intervention selection, and what-if capacity simulation.
6. Prepared Looker dashboard assets for executive, retention ops, model monitoring, and what-if simulator views.

## Architecture
- Batch ingestion: Kaggle CSV -> BigQuery `raw.telco_customer_churn`.
- Optional streaming ingestion: Pub/Sub -> BigQuery `raw.usage_events_stream`.
- Transformations: dbt models build `staging`, `mart`, `ml`, and `monitoring` datasets.
- Modeling: BigQuery ML baseline plus optional Vertex AI challenger.
- Serving: retention action list, decision engine, and capacity what-if simulator.
- BI: Looker explores and dashboard specifications.

## Data Model
- `raw`: source landing tables such as `telco_customer_churn`; optional `usage_events_stream`.
- `staging`: cleaned source-like models.
- `mart`: customer dimensions, usage/billing/support facts, retention outputs, what-if simulator.
- `ml`: training features and prediction outputs such as `fct_churn_training`, `customer_churn_scores`, and optional `customer_churn_scores_vertex`.
- `monitoring`: model metrics, champion selection, precision/recall, drift, and data-quality results.

## Core Run Order
```powershell
python scripts\ingest_kaggle_raw.py
python scripts\load_raw_to_bq.py
cd dbt
dbt run --exclude fct_score_distribution_daily
dbt test
cd ..
python scripts\run_sql_folder.py --folder sql\bqml
cd dbt
dbt run --select fct_score_distribution_daily
cd ..
python scripts\run_sql_folder.py --folder sql\monitoring
python scripts\run_sql_folder.py --folder sql\serving
```

Optional Vertex challenger:

```powershell
python ml\vertex\train_vertex_tabular.py
python ml\vertex\evaluate_vertex.py
python ml\vertex\batch_predict_vertex.py
```

Optional streaming:

```bash
bash infra/pubsub_setup.sh <project_id> us-central1
python scripts/pubsub_usage_producer.py
```

## Final Evidence / Screenshots
Capture screenshots under `docs/screenshots/` for the final project walkthrough. The strongest set is:

1. **BigQuery warehouse structure**: datasets `raw`, `staging`, `mart`, `ml`, and `monitoring`.
2. **Raw ingestion**: `raw.telco_customer_churn` preview or row count.
3. **dbt build quality**: terminal output for `dbt run` / `dbt test`, or BigQuery tables such as `mart.customer_health_snapshot_daily` and `ml.fct_churn_training`.
4. **BQML scoring**: `ml.churn_bqml_v1` model and `ml.customer_churn_scores` preview.
5. **Model monitoring**: `monitoring.model_metrics_history`, `monitoring.model_champion_selection`, `monitoring.precision_recall_top10_daily`, and `monitoring.data_quality_results`.
6. **Retention decision output**: `mart.retention_decision_engine` showing `customer_id`, `predicted_churn_prob`, `mrr_at_risk`, `roi_score`, and `selected_for_intervention`.
7. **Looker dashboards**: Executive, Retention Ops, Model Monitoring, and What-if Simulator dashboards if available.

Optional screenshots:

- **Vertex AI challenger**: Vertex AI Model Registry and Training Pipeline status if the Vertex run completed.
- **Streaming demo**: Pub/Sub topic `usage-events-topic` and `raw.usage_events_stream` if optional streaming is enabled.

## Demo Script
See `docs/demo_script.md` for the final walkthrough order and screenshot checklist.

## Notes
- BQML is the fast baseline path used by the main serving SQL.
- Vertex AI is an optional challenger path and can take significantly longer to train.
- Pub/Sub is optional and demonstrates real-time usage event ingestion; the main pipeline can run from the Kaggle batch load alone.
