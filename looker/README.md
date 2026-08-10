# Looker (BigQuery) wiring

## Prerequisites (BigQuery tables)

Looker only **reads** warehouse tables. Ensure these exist first:

```powershell
cd e:\churn-intelligence-gcp
python -m pip install -r requirements.txt
python scripts/run_sql_folder.py --folder sql/monitoring
python scripts/run_sql_folder.py --folder sql/serving
python scripts/verify_looker_tables.py
```

Required tables: `ml.customer_churn_scores`, `mart.retention_*`, `mart.dim_customer`,
`monitoring.model_*`, `monitoring.precision_recall_top10_daily`,
`monitoring.prediction_distribution_history`.

## 1) Project id

[`constants.lkml`](constants.lkml) `BIGQUERY_PROJECT_ID` must match `GCP_PROJECT_ID` in `.env`
(currently `churn-495812`).

## 2) BigQuery connection in Looker

1. In Looker: **Admin → Connections → New Connection**.
2. Dialect: **Google BigQuery Standard SQL**.
3. Use service account JSON (`churn-credentials.json`) that can **read** datasets `mart`, `ml`, `monitoring`
   and run queries in **`us-central1`**.
4. Name the connection exactly:

```text
churn_bigquery
```

   Wired in [`models/churn_intelligence.model.lkml`](models/churn_intelligence.model.lkml).
   If you choose another name, update the `connection:` line to match.

## 3) Load this LookML

- Point the Looker project at this repo’s `looker/` folder (Git sync or copy).
- Expected layout:

```text
looker/
  constants.lkml
  models/churn_intelligence.model.lkml
  views/*.view.lkml
  dashboards/*.dashboard.lookml
```

- Run **Validate LookML** in the Looker IDE.

## 4) Explores

| Explore | Use for |
|---------|---------|
| `customer_risk` + `dim_customer` | Executive KPIs |
| `retention_decision_engine` | Retention Ops (filter `selected_for_intervention`) |
| `retention_what_if` / `retention_marginal_gain` | What-if simulator |
| `model_champion` / `precision_recall_top10` / `model_metrics_history` | Model monitoring |
| `prediction_distribution` | Score drift |

**First explore:** `retention_decision_engine` → `selected_for_intervention = Yes` → sort by `priority_rank`.

## 5) Dashboards (LookML)

| File | Dashboard |
|------|-----------|
| `executive.dashboard.lookml` | Executive KPIs |
| `retention_ops.dashboard.lookml` | Intervention shortlist |
| `model_monitoring.dashboard.lookml` | Champion + AUC + precision/recall |
| `what_if_simulator.dashboard.lookml` | Scenarios + marginal gain |

Markdown specs remain in `*.dashboard.md` for portfolio notes.

## 6) Screenshot checklist

Save under `docs/screenshots/`: project sidebar, `customer_risk`, `retention_decision_engine`, what-if, champion, saved dashboards.
