# Looker BigQuery connection setup

Complete these steps in the **Looker UI** (cannot be automated without a Looker instance).

## Create the connection

1. Open Looker → **Admin → Connections → New Connection**
2. Fill in:

| Field | Value |
|-------|--------|
| Name | `churn_bigquery` (must match `models/churn_intelligence.model.lkml`) |
| Dialect | Google BigQuery Standard SQL |
| Project Name | `churn-495812` |
| Dataset | `mart` (default; explores use fully-qualified tables) |
| Authentication | Service Account |
| Service Account Email | from `churn-credentials.json` → `client_email` |
| Service Account JSON | upload `churn-credentials.json` |
| Billing Project ID | `churn-495812` |

3. Set query location / region to **`us-central1`** if the UI asks.
4. Click **Test These Settings** → should succeed.
5. Save.

## Wire LookML (already done in repo)

- `looker/models/churn_intelligence.model.lkml` → `connection: "churn_bigquery"`
- `looker/constants.lkml` → `BIGQUERY_PROJECT_ID = churn-495812`

If you name the connection differently, change the `connection:` line only.

## Load project

1. Create a Looker project (or use Git connected to this repo).
2. Ensure the Looker project root contains the contents of `looker/` (or set the project folder to `looker/`).
3. **Develop → Validate LookML**.

## First explore (Retention Decision Engine)

1. **Explore → Retention Decision Engine**
2. Filters: `Selected for Intervention` = **Yes**
3. Fields: `priority_rank`, `customer_id`, `predicted_churn_prob`, `roi_score`, `policy_action_name`, `plan_tier`
4. Sort by `priority_rank` ascending
5. Run

Then open LookML dashboards: **Executive**, **Retention Ops**, **Model Monitoring**, **What-if Simulator**.
