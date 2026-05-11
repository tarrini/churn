"""
Batch-predict churn with a trained Vertex AutoML Tabular model from BigQuery
ml.fct_churn_training into a Vertex-managed BigQuery predictions table, then
materialize ml.customer_churn_scores_vertex alongside the existing BQML table.

Model pointer (same as evaluate_vertex.py):
  --model-resource-name, or VERTEX_MODEL_RESOURCE_NAME, or last_vertex_model.resource_name
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from datetime import datetime, timezone

from dotenv import load_dotenv
from google.cloud import aiplatform
from google.cloud import bigquery

from _vertex_common import resolve_model_resource_name

load_dotenv()

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
LOCATION = os.getenv("GCP_LOCATION", "us-central1")
STAGING_BUCKET = os.getenv("GCS_VERTEX_STAGING_BUCKET")
BQ_SOURCE_VIEW = os.getenv("VERTEX_BATCH_PREDICT_BQ_URI", "").strip()
TARGET_COLUMN = os.getenv("VERTEX_TARGET_COLUMN", "churned_30d")


def _normalize_staging_bucket(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("gs://"):
        return raw.rstrip("/")
    return f"gs://{raw.rstrip('/')}"


def _default_bq_source() -> str:
    table = os.getenv("VERTEX_TRAINING_BQ_TABLE", "ml.fct_churn_training")
    return f"bq://{PROJECT_ID}.{table}"


def _parse_output_table(job) -> str:
    info = job.output_info
    if not info or not getattr(info, "bigquery_output_dataset", None) or not getattr(
        info, "bigquery_output_table", None
    ):
        raise RuntimeError(f"Unexpected batch output (see job in console): {info}")
    ds = info.bigquery_output_dataset
    if ds.startswith("bq://"):
        ds = ds[len("bq://") :]
    return f"`{ds}.{info.bigquery_output_table}`"


def _record_scores_probability_expr(fname: str, scores_sf) -> str:
    nm = _safe_ident(fname)
    if getattr(scores_sf, "mode", "") == "REPEATED":
        return f"SAFE_CAST(t.`{nm}`.scores[SAFE_OFFSET(1)] AS FLOAT64)"
    return f"SAFE_CAST(t.`{nm}`.scores AS FLOAT64)"


def _infer_probability_sql(fields: list, target_column: str) -> str:
    target_key = target_column.lower().replace("_", "")
    floats = {"FLOAT", "FLOAT64"}

    for f in fields:
        ln = (f.name or "").lower().replace("_", "")
        if f.field_type in floats:
            if "prob" in ln or ln.endswith("confidence") or ln == "score":
                return f"SAFE_CAST(t.`{_safe_ident(f.name)}` AS FLOAT64)"

    record_fields = [f for f in fields if f.field_type == "RECORD"]
    for f in sorted(
        record_fields,
        key=lambda x: (
            0 if target_key in (x.name or "").lower().replace("_", "") else 1,
            0 if (x.name or "").lower().startswith("predict") else 1,
            len(x.name or ""),
        ),
    ):
        nested = {sf.name: sf for sf in f.fields}
        scores = nested.get("scores")
        if scores is not None and scores.field_type in floats:
            return _record_scores_probability_expr(f.name, scores)

    if record_fields:
        f = sorted(record_fields, key=lambda z: len(z.name or ""))[0]
        nested = {sf.name: sf for sf in f.fields}
        if "scores" in nested:
            return _record_scores_probability_expr(f.name, nested["scores"])

    sys.exit(
        "Could not infer probability SQL from Vertex batch predictions schema.\n"
        "Inspect `predictions` column types in BigQuery and set VERTEX_SCORE_SQL to "
        'a FLOAT64 SELECT expression using alias `t` (example: SAFE_CAST(t.`churned_30d`'
        '.scores[SAFE_OFFSET(1)] AS FLOAT64)).'
    )


def _safe_ident(name: str) -> str:
    if not name or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
        raise ValueError(f"Unsupported column identifier: {name!r}")
    return name


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Vertex AutoML batch predict → BigQuery scores table.")
    p.add_argument("--model-resource-name", default=None)
    return p.parse_args()


def main() -> None:
    args = parse_args()
    if not PROJECT_ID:
        sys.exit("Set GCP_PROJECT_ID")

    staging = STAGING_BUCKET or ""
    if not staging:
        sys.exit("Set GCS_VERTEX_STAGING_BUCKET for Vertex batch prediction.")
    aiplatform.init(
        project=PROJECT_ID,
        location=LOCATION,
        staging_bucket=_normalize_staging_bucket(staging),
    )

    model_rn = resolve_model_resource_name(args.model_resource_name)
    model = aiplatform.Model(model_rn)

    bq_source = BQ_SOURCE_VIEW or _default_bq_source()
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")

    custom_score_sql = os.getenv("VERTEX_SCORE_SQL", "").strip()

    batch_job = model.batch_predict(
        job_display_name=f"vertex_churn_batch_{stamp}",
        bigquery_source=bq_source,
        bigquery_destination_prefix=f"bq://{PROJECT_ID}",
        instances_format="bigquery",
        sync=True,
    )

    out_fqn = _parse_output_table(batch_job)
    print(f"Batch predictions table: {out_fqn}")

    client = bigquery.Client(project=PROJECT_ID)
    fq_clean = out_fqn.strip("`")
    tbl = client.get_table(fq_clean)

    score_expr = custom_score_sql or _infer_probability_sql(tbl.schema, TARGET_COLUMN)
    cols = [f.name for f in tbl.schema]
    if "customer_id" in cols:
        cid = "customer_id"
    else:
        cid = next((c for c in cols if re.search(r"customer_?id", str(c), re.I)), "")
    if "monthly_mrr" in cols:
        mrr = "monthly_mrr"
    else:
        mrr = ""

    if not cid or not mrr or cid not in cols or mrr not in cols:
        sys.exit(
            f"Expected columns customer_id-like and monthly_mrr in predictions export; "
            f"present: {cols}. Set VERTEX_SCORE_SQL manually."
        )

    sql = f"""
CREATE OR REPLACE TABLE `{PROJECT_ID}.ml.customer_churn_scores_vertex` AS
SELECT
  CURRENT_DATE() AS snapshot_date,
  t.`{_safe_ident(cid)}` AS customer_id,
  {score_expr} AS predicted_churn_prob,
  t.`{_safe_ident(mrr)}` AS monthly_mrr,
  ({score_expr}) * t.`{_safe_ident(mrr)}` AS mrr_at_risk
FROM {out_fqn} AS t
"""

    client.query(sql).result()
    ts = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
    print(f"[{ts}] Created `{PROJECT_ID}.ml.customer_churn_scores_vertex` from Vertex batch output")


if __name__ == "__main__":
    main()
