"""
Submit a Vertex AI AutoML Tabular binary-classification job using BigQuery
`ml.fct_churn_training` (built by dbt).

Prerequisites:
  - APIs: Vertex AI API, BigQuery API
  - A GCS bucket for staging (Vertex uploads artifacts here)
  - Service account with roles such as: Vertex AI User, BigQuery Data Viewer on the
    training table, Storage Object Admin on the staging bucket (see GCP docs)

Environment:
  - GCP_PROJECT_ID (required)
  - GCP_LOCATION (default us-central1)
  - GCS_VERTEX_STAGING_BUCKET (required), e.g. gs://my-project-vertex-staging
  - VERTEX_TRAINING_BQ_TABLE (optional), default ml.fct_churn_training
  - VERTEX_AUTOML_BUDGET_MILLI_NODE_HOURS (optional), min 1000 = 1 node-hour
  - GOOGLE_APPLICATION_CREDENTIALS for local runs
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timezone

from dotenv import load_dotenv
from google.cloud import aiplatform

from _vertex_common import last_model_path

load_dotenv()

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
LOCATION = os.getenv("GCP_LOCATION", "us-central1")
STAGING_BUCKET = os.getenv("GCS_VERTEX_STAGING_BUCKET")
BQ_TABLE = os.getenv("VERTEX_TRAINING_BQ_TABLE", "ml.fct_churn_training")
TARGET_COLUMN = os.getenv("VERTEX_TARGET_COLUMN", "churned_30d")
MODEL_DISPLAY_NAME = os.getenv("VERTEX_MODEL_DISPLAY_NAME", "churn_vertex_automl_v1")


def _normalize_staging_bucket(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("gs://"):
        return raw.rstrip("/")
    return f"gs://{raw.rstrip('/')}"


def _budget_milli_node_hours() -> int:
    raw = os.getenv("VERTEX_AUTOML_BUDGET_MILLI_NODE_HOURS", "1000")
    try:
        v = int(raw)
    except ValueError as exc:
        raise SystemExit(
            f"VERTEX_AUTOML_BUDGET_MILLI_NODE_HOURS must be an integer, got {raw!r}"
        ) from exc
    if v < 1000 or v > 72000:
        raise SystemExit(
            "VERTEX_AUTOML_BUDGET_MILLI_NODE_HOURS must be between 1000 and 72000 "
            "(see Vertex AutoML tabular limits)."
        )
    return v


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Run Vertex AutoML Tabular training on BQ features.")
    p.add_argument(
        "--budget-milli-node-hours",
        type=int,
        default=None,
        help="Override VERTEX_AUTOML_BUDGET_MILLI_NODE_HOURS (min 1000).",
    )
    return p.parse_args()


def main() -> None:
    args = parse_args()

    if not PROJECT_ID:
        sys.exit("Set GCP_PROJECT_ID in the environment or .env")

    staging = STAGING_BUCKET
    if not staging:
        sys.exit(
            "Set GCS_VERTEX_STAGING_BUCKET to a bucket URI, e.g. gs://your-project-vertex-staging "
            "(create the bucket in the same region as Vertex, typically us-central1)."
        )

    if args.budget_milli_node_hours is not None:
        budget = args.budget_milli_node_hours
        if budget < 1000 or budget > 72000:
            sys.exit(
                "--budget-milli-node-hours must be between 1000 and 72000 "
                "(Vertex AutoML tabular limits)."
            )
    else:
        budget = _budget_milli_node_hours()

    bq_uri = f"bq://{PROJECT_ID}.{BQ_TABLE}"
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    dataset_name = f"churn_tabular_{stamp}"

    aiplatform.init(
        project=PROJECT_ID,
        location=LOCATION,
        staging_bucket=_normalize_staging_bucket(staging),
    )

    print(f"Creating TabularDataset from {bq_uri} (display_name={dataset_name}) …")
    dataset = aiplatform.TabularDataset.create(
        display_name=dataset_name,
        bq_source=bq_uri,
        sync=True,
    )

    # Only these columns get transformations; others (e.g. customer_id, snapshot_date)
    # are omitted and ignored by AutoML; target_column is specified separately.
    column_specs = {
        "monthly_mrr": "numeric",
        "usage_drop_pct": "numeric",
        "failed_invoices_90d": "numeric",
        "avg_resolution_hours_30d": "numeric",
    }

    job = aiplatform.AutoMLTabularTrainingJob(
        display_name=f"automl_churn_{stamp}",
        optimization_prediction_type="classification",
        optimization_objective="maximize-au-roc",
        column_specs=column_specs,
    )

    print(
        f"Starting AutoML Tabular training (budget_milli_node_hours={budget}). "
        "This typically takes tens of minutes to several hours."
    )
    model = job.run(
        dataset=dataset,
        target_column=TARGET_COLUMN,
        training_fraction_split=0.7,
        validation_fraction_split=0.15,
        test_fraction_split=0.15,
        budget_milli_node_hours=budget,
        model_display_name=f"{MODEL_DISPLAY_NAME}_{stamp}",
        disable_early_stopping=False,
        sync=True,
    )

    print("Training finished.")
    print(f"  model_display_name: {model.display_name}")
    print(f"  model_resource_name: {model.resource_name}")
    lp = last_model_path()
    lp.write_text(model.resource_name.strip() + "\n", encoding="utf-8")
    print(f"  wrote model resource name to {lp} (evaluate_vertex / batch_predict_vertex)")


if __name__ == "__main__":
    main()
