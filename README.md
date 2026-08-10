# Customer Churn & Revenue Risk Intelligence Platform

## Problem Statement
Retention teams often identify churn too late and cannot clearly quantify revenue exposure.

## Business Value
This project predicts churn risk, estimates `mrr_at_risk`, and creates actionable retention worklists so teams can intervene early.

## Live deployment
| Item | Value |
|------|--------|
| GCP project | `churn-499415` |
| BigQuery location | `US` |
| Cloud Run API |
| Pub/Sub topic | `usage-events-topic` |

### Cloud Run endpoints
- `GET /health` — service health
- `GET /customers/{customer_id}/risk` — churn score + retention decision
- `GET /interventions/today?limit=5` — top intervention list
- `GET /model/metrics` — champion / precision-recall snapshot

Example:
```powershell
curl.exe --ssl-no-revoke https://churn-intelligence-api-764726271474.us-central1.run.app/health
curl.exe --ssl-no-revoke "https://churn-intelligence-api-764726271474.us-central1.run.app/interventions/today?limit=5"
```

### Project Outcomes
1. Built an **end-to-end churn analytics platform** with **batch** (Kaggle CSV → BigQuery `raw`) and **streaming** (Pub/Sub → `raw.usage_events_stream`) ingestion.
2. Transformed product-, billing-, and support-style landing data into analytics-ready **star-schema marts** via dbt.
3. Trained a **BigQuery ML** baseline and a **Vertex AI** challenger; scores and metrics support champion comparison.
4. Designed a **Retention Decision Engine** (`mart.retention_decision_engine`): risk-driver policy, expected MRR saved, ROI, and `selected_for_intervention` under a capacity cap.
5. Delivered **Looker** dashboards for executives, retention ops, model monitoring, and what-if capacity planning.
6. Served scores and interventions through a **Cloud Run** REST API (`services/churn_api`).

## Architecture
- Batch ingestion: Kaggle CSV → BigQuery `raw.telco_customer_churn`.
- Streaming ingestion: Pub/Sub → BigQuery `raw.usage_events_stream`.
- Transformations: dbt models in `staging`, `mart`, `ml`, and `monitoring`.
- Modeling: BigQuery ML baseline + Vertex AI challenger (champion selection in monitoring).
- Serving: retention action list, decision engine, what-if simulator.
- API: Cloud Run FastAPI service reading BigQuery marts.
- BI: Looker explores + dashboards.

```text
Kaggle CSV                     Usage events
    │                               │
    ▼                               ▼
BigQuery raw                 Pub/Sub → raw.usage_events_stream
    │
    ▼
dbt (staging → mart → ml)
    │
    ▼
BQML train + score → ml.customer_churn_scores
    │
    ▼
Serving SQL → retention_decision_engine + what-if
    │
    ├──────────────► Looker dashboards
    └──────────────► Cloud Run API
```

## Data Model
- `raw`: `telco_customer_churn`, `usage_events_stream`
- `staging`: cleaned source-like models
- `mart`: dimensions, facts, retention decision engine, what-if simulator
- `ml`: `fct_churn_training`, `customer_churn_scores`, optional `customer_churn_scores_vertex`
- `monitoring`: model metrics, champion selection, precision/recall, data quality

## KPI definitions
- `mrr_at_risk = predicted_churn_prob * monthly_mrr`
- `high_risk_customers = count(predicted_churn_prob >= 0.7)`
- Intervention shortlist = top customers by ROI with `selected_for_intervention = true`

## Core Run Order
```powershell
cd C:\Users\praka\churn-intelligence-gcp
$env:GCP_PROJECT_ID = "churn-499415"
$env:GCP_LOCATION = "US"
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\Users\praka\churn-intelligence-gcp\churn-credentials.json"

python scripts\ingest_kaggle_raw.py
python scripts\load_raw_to_bq.py
cd dbt
dbt run
dbt test
cd ..
python scripts\run_sql_folder.py --folder sql\bqml
python scripts\run_sql_folder.py --folder sql\monitoring
python scripts\run_sql_folder.py --folder sql\serving
```

### Vertex AI challenger
```powershell
$env:GCS_VERTEX_STAGING_BUCKET = "gs://churn-499415-vertex-staging"
python ml\vertex\train_vertex_tabular.py
python ml\vertex\evaluate_vertex.py
python ml\vertex\batch_predict_vertex.py
```

### Streaming (Pub/Sub)
```powershell
# Create topic/subscription + table (one-time; use project owner account)
# Then publish sample events:
python scripts\pubsub_usage_producer.py
```

### Cloud Run deploy
```powershell
gcloud.cmd run deploy churn-intelligence-api `
  --source=services/churn_api `
  --region=us-central1 `
  --allow-unauthenticated `
  --set-env-vars="GCP_PROJECT_ID=churn-499415,BQ_MART_DATASET=mart,BQ_ML_DATASET=ml,BQ_MONITORING_DATASET=monitoring" `
  --memory=512Mi
```

### Cloud Composer (schedule daily / weekly)
Cloud Run **serves** results. Composer **schedules** dbt + BQML + serving (and weekly Vertex).

See `infra/COMPOSER_SETUP.md`.

### Looker
1. Set `BIGQUERY_PROJECT_ID` to `churn-499415` in `looker/constants.lkml`
2. Connection name: `churn_bigquery` (BigQuery location **US**)
3. Dashboards: Executive, Retention Ops, Model Monitoring, What-if Simulator

## Implemented vs optional
| Component | Status |
|-----------|--------|
| BigQuery + dbt + BQML + serving | Implemented |
| Vertex AI challenger | Implemented |
| Looker dashboards | Implemented |
| Pub/Sub streaming | Implemented |
| Cloud Run API | Implemented |
| Cloud Composer (daily/weekly schedule) | Setup ready — see `infra/COMPOSER_SETUP.md` |
| Dataflow / Data Fusion | Optional |

## Final Evidence / Screenshots
Save under `docs/screenshots/`:

1. BigQuery datasets: `raw`, `staging`, `mart`, `ml`, `monitoring`
2. `raw.telco_customer_churn` preview
3. `raw.usage_events_stream` preview (streaming)
4. `ml.customer_churn_scores` preview
5. `mart.retention_decision_engine` preview
6. Looker: Executive, Retention Ops, Model Monitoring, What-if
7. Pub/Sub topic `usage-events-topic`
8. Cloud Run service + `/health` and `/interventions/today` JSON
9. Vertex AI Model Registry / training job + `monitoring.model_champion_selection`

## Notes
- BigQuery datasets for this deployment are in location **US** (`GCP_LOCATION=US`).
- BQML is the fast baseline; Vertex AI is the challenger used for champion comparison.
- On Windows PowerShell, use `curl.exe --ssl-no-revoke` if SSL revocation checks fail.
