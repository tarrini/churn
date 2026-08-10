"""Cloud Run API: churn risk, interventions, model metrics."""

from __future__ import annotations

import os
from typing import Any

from fastapi import FastAPI, HTTPException, Query
from google.cloud import bigquery

app = FastAPI(title="Churn Intelligence API", version="1.0.0")

PROJECT_ID = os.environ.get("GCP_PROJECT_ID", "")
MART = os.environ.get("BQ_MART_DATASET", "mart")
ML = os.environ.get("BQ_ML_DATASET", "ml")
MONITORING = os.environ.get("BQ_MONITORING_DATASET", "monitoring")


def client() -> bigquery.Client:
    if not PROJECT_ID:
        raise HTTPException(status_code=500, detail="GCP_PROJECT_ID not set")
    return bigquery.Client(project=PROJECT_ID)


def as_dict(row: bigquery.table.Row) -> dict[str, Any]:
    return dict(row.items())


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/customers/{customer_id}/risk")
def customer_risk(customer_id: str) -> dict[str, Any]:
    q = f"""
      SELECT
        s.customer_id,
        s.snapshot_date,
        s.predicted_churn_prob,
        s.monthly_mrr,
        s.mrr_at_risk,
        d.primary_risk_driver,
        d.policy_action_name,
        d.expected_mrr_saved,
        d.roi_score,
        d.selected_for_intervention
      FROM `{PROJECT_ID}.{ML}.customer_churn_scores` s
      LEFT JOIN `{PROJECT_ID}.{MART}.retention_decision_engine` d
        USING (customer_id)
      WHERE s.customer_id = @customer_id
      ORDER BY s.snapshot_date DESC
      LIMIT 1
    """
    job = client().query(
        q,
        job_config=bigquery.QueryJobConfig(
            query_parameters=[bigquery.ScalarQueryParameter("customer_id", "STRING", customer_id)]
        ),
    )
    rows = list(job.result())
    if not rows:
        raise HTTPException(status_code=404, detail="Customer not found")
    return as_dict(rows[0])


@app.get("/interventions/today")
def interventions_today(limit: int = Query(50, ge=1, le=500)) -> dict[str, Any]:
    q = f"""
      SELECT
        customer_id, snapshot_date, predicted_churn_prob, monthly_mrr, mrr_at_risk,
        primary_risk_driver, policy_action_name, expected_mrr_saved, roi_score, priority_rank
      FROM `{PROJECT_ID}.{MART}.retention_decision_engine`
      WHERE selected_for_intervention = TRUE
      ORDER BY priority_rank
      LIMIT @limit
    """
    job = client().query(
        q,
        job_config=bigquery.QueryJobConfig(
            query_parameters=[bigquery.ScalarQueryParameter("limit", "INT64", limit)]
        ),
    )
    rows = [as_dict(r) for r in job.result()]
    return {"count": len(rows), "interventions": rows}


@app.get("/model/metrics")
def model_metrics() -> dict[str, Any]:
    c = client()
    champion = list(
        c.query(
            f"SELECT * FROM `{PROJECT_ID}.{MONITORING}.model_champion_selection` ORDER BY selected_at DESC LIMIT 1"
        ).result()
    )
    pr = list(
        c.query(
            f"SELECT * FROM `{PROJECT_ID}.{MONITORING}.precision_recall_top10_daily` ORDER BY snapshot_date DESC LIMIT 1"
        ).result()
    )
    return {
        "champion": as_dict(champion[0]) if champion else None,
        "precision_recall_top10": as_dict(pr[0]) if pr else None,
    }
