"""
Pull evaluation metrics from a trained Vertex AutoML Tabular model and insert into
monitoring.model_metrics_history (aligned with sql/monitoring/010).

Model pointer (first match wins):
  --model-resource-name, or VERTEX_MODEL_RESOURCE_NAME, or ml/vertex/last_vertex_model.resource_name
"""

from __future__ import annotations

import argparse
import os
import sys
from datetime import datetime, timezone
from typing import Any

from dotenv import load_dotenv
from google.cloud import aiplatform
from google.cloud import bigquery

from _vertex_common import resolve_model_resource_name

load_dotenv()

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
LOCATION = os.getenv("GCP_LOCATION", "us-central1")
STAGING_BUCKET = os.getenv("GCS_VERTEX_STAGING_BUCKET")
METRICS_MODEL_NAME = os.getenv("VERTEX_EVAL_MODEL_NAME", "churn_vertex_automl_v1")


def _normalize_staging_bucket(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("gs://"):
        return raw.rstrip("/")
    return f"gs://{raw.rstrip('/')}"


def _scalar_float(val: Any) -> float | None:
    if val is None:
        return None
    if isinstance(val, (int, float)):
        return float(val)
    if isinstance(val, dict):
        for k in ("doubleValue", "numberValue", "floatValue"):
            if k in val:
                try:
                    return float(val[k])
                except (TypeError, ValueError):
                    pass
        for v in val.values():
            got = _scalar_float(v)
            if got is not None:
                return got
    return None


def _deep_find_named_float(d: Any, *name_fragments: str) -> float | None:
    """Find a float by matching key names (case-insensitive, fragment substrings)."""
    if isinstance(d, dict):
        for k, v in d.items():
            kl = str(k).lower().replace("_", "").replace("-", "")
            if all(f in kl for f in name_fragments):
                got = _scalar_float(v)
                if got is not None:
                    return got
            got = _deep_find_named_float(v, *name_fragments)
            if got is not None:
                return got
    if isinstance(d, list):
        for item in d:
            got = _deep_find_named_float(item, *name_fragments)
            if got is not None:
                return got
    return None


def metrics_from_evaluation_dict(blob: dict) -> tuple[float | None, float | None, float | None, float | None]:
    metrics = blob.get("metrics") or {}
    auc = (
        _deep_find_named_float(metrics, "auc", "roc")
        or _deep_find_named_float(metrics, "auroc")
        or _deep_find_named_float(metrics, "receiveroperatingcharacteristic")
    )
    log_loss = _deep_find_named_float(metrics, "log", "loss") or _deep_find_named_float(metrics, "logloss")
    precision = _deep_find_named_float(metrics, "precision") or _deep_find_named_float(
        metrics, "precisionat"
    )
    recall = _deep_find_named_float(metrics, "recall") or _deep_find_named_float(metrics, "recallat")

    if precision is None or recall is None:
        cms = metrics.get("confidenceMetrics") or metrics.get("confidence_metrics")
        if isinstance(cms, list) and cms:
            mid = cms[len(cms) // 2]
            if isinstance(mid, dict):
                if precision is None:
                    precision = _scalar_float(mid.get("precision")) or _deep_find_named_float(mid, "precision")
                if recall is None:
                    recall = _scalar_float(mid.get("recall")) or _deep_find_named_float(mid, "recall")

    return auc, log_loss, precision, recall


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Log Vertex evaluation metrics to BigQuery monitoring table.")
    p.add_argument("--model-resource-name", default=None)
    return p.parse_args()


def main() -> None:
    args = parse_args()
    if not PROJECT_ID:
        sys.exit("Set GCP_PROJECT_ID")

    if STAGING_BUCKET:
        aiplatform.init(
            project=PROJECT_ID,
            location=LOCATION,
            staging_bucket=_normalize_staging_bucket(STAGING_BUCKET),
        )
    else:
        aiplatform.init(project=PROJECT_ID, location=LOCATION)

    model_rn = resolve_model_resource_name(args.model_resource_name)
    model = aiplatform.Model(model_rn)
    evaluations = model.list_model_evaluations()

    if not evaluations:
        sys.exit("No model evaluations attached to this Vertex model.")

    def _ev_time(ev) -> str:
        d = ev.to_dict()
        return str(d.get("createTime") or d.get("create_time") or "")

    evaluations = sorted(evaluations, key=_ev_time, reverse=True)
    auc, log_loss, precision, recall = metrics_from_evaluation_dict(evaluations[0].to_dict())

    def lit_f(value: float | None) -> str:
        if value is None:
            return "CAST(NULL AS FLOAT64)"
        return str(float(value))

    insert_sql = f"""
INSERT INTO `{PROJECT_ID}.monitoring.model_metrics_history`
  (run_ts, model_name, auc, log_loss, `precision`, `recall`)
VALUES (
  CURRENT_TIMESTAMP(),
  @model_name,
  {lit_f(auc)},
  {lit_f(log_loss)},
  {lit_f(precision)},
  {lit_f(recall)}
)
"""

    cfg = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("model_name", "STRING", METRICS_MODEL_NAME),
        ]
    )
    client = bigquery.Client(project=PROJECT_ID)
    client.query(insert_sql, job_config=cfg).result()
    ts = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    print(f"[{ts}] Inserted Vertex metrics row for '{METRICS_MODEL_NAME}':")
    print(f"  auc={auc} log_loss={log_loss} precision={precision} recall={recall}")


if __name__ == "__main__":
    main()
