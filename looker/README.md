# Looker (BigQuery) wiring

## 1) One-time project id

Edit `constants.lkml` and set `BIGQUERY_PROJECT_ID` to the same value as `GCP_PROJECT_ID` in your `.env` (the project where `raw`, `staging`, `mart`, `ml`, and `monitoring` datasets live).

## 2) BigQuery connection in Looker

1. In Looker: **Admin → Connections → New Connection** (or edit an existing BigQuery connection).
2. Use a service account JSON that can read the datasets above (and run queries in the correct region, e.g. `us-central1`).
3. Copy the **connection name** from Looker and set it in `models/churn_intelligence.model.lkml`:

```lkml
connection: "your_connection_name_here"
```

## 3) Load this LookML

- **Looker Git integration:** point the project at this repo’s `looker/` folder (or copy these files into your Looker project).
- **Validate:** run **Validate LookML** (or `lookml` CI if you use it). Fix any connection or permission errors before building content.

## 4) Building dashboards

Use the explores defined in `churn_intelligence.model.lkml`:

| Explore | Use for |
|---------|---------|
| `customer_risk` + `dim_customer` | Executive KPIs (MRR at risk, high-risk count), churn prob trends, segment splits |
| `retention_decision_engine` | Retention Ops: prioritize by `roi_score`, filter `selected_for_intervention = Yes` |
| `retention_what_if` | Capacity × threshold scenarios, `net_expected_value` |
| `retention_marginal_gain` | Marginal lift when raising capacity |
| `model_champion` | BQML vs Vertex champion summary |
| `precision_recall_top10` | **`precision_at_10`** / **`recall_at_10`** by `snapshot_date` |
| `model_metrics_history` | AUC / log loss trends by `run_ts` and `model_name` |

Suggested tiles match the Markdown specs under `dashboards/` (Executive, Retention Ops, Model Monitoring, What-if Simulator).

## 5) Screenshot checklist (for README / portfolio)

Save PNGs under `docs/screenshots/` (create the folder if needed), in roughly this order:

1. Looker **Project** sidebar showing model + explores.
2. **Explore** preview: `customer_risk` with `dim_customer` — KPI tiles or table (plan / country breakdown).
3. **Explore**: `retention_decision_engine` — table sorted by `roi_score`, filter `selected_for_intervention`.
4. **Explore**: `retention_what_if` — bar chart `net_expected_value` by `scenario_id`.
5. **Explore**: `retention_marginal_gain` — marginal value by capacity step.
6. **Explore**: `model_champion` — champion + AUC fields.
7. One **saved dashboard** (or “Edit dashboard”) view for Executive; repeat for Ops, Monitoring, What-if if you split them.

Optional: blur any internal project names in screenshots if you share publicly; keep one unredacted copy for recruiters on request.
