"""
Verify BigQuery tables required by looker/ explores exist.

Usage:
  python scripts/verify_looker_tables.py
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery

_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(_ROOT / ".env")


def _resolve_credentials_path() -> None:
    raw = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if not raw:
        return
    p = Path(raw.strip().strip('"'))
    p = (_ROOT / p).resolve() if not p.is_absolute() else p.resolve()
    if not p.is_file():
        os.environ.pop("GOOGLE_APPLICATION_CREDENTIALS", None)
        print(
            f"Warning: service account JSON not found at {p}; "
            "using Application Default Credentials instead."
        )
        return
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(p)


REQUIRED_TABLES = [
    "ml.customer_churn_scores",
    "mart.dim_customer",
    "mart.retention_action_list",
    "mart.retention_decision_engine",
    "mart.retention_what_if_simulator",
    "mart.retention_capacity_marginal_gain",
    "monitoring.model_metrics_history",
    "monitoring.precision_recall_top10_daily",
    "monitoring.model_champion_selection",
    "monitoring.prediction_distribution_history",
]


def main() -> None:
    _resolve_credentials_path()
    project = os.getenv("GCP_PROJECT_ID")
    if not project:
        sys.exit("Set GCP_PROJECT_ID in .env")

    client = bigquery.Client(project=project)
    missing = []
    present = []
    for fq in REQUIRED_TABLES:
        table_id = f"{project}.{fq}"
        try:
            client.get_table(table_id)
            present.append(fq)
            print(f"OK  {fq}")
        except Exception:
            missing.append(fq)
            print(f"MISSING  {fq}")

    print()
    print(f"Present: {len(present)}/{len(REQUIRED_TABLES)}")
    if missing:
        print("Run these to create missing tables:")
        print("  python scripts/run_sql_folder.py --folder sql/monitoring")
        print("  python scripts/run_sql_folder.py --folder sql/serving")
        print("(Requires ml.customer_churn_scores from sql/bqml first.)")
        sys.exit(1)
    print("All Looker prerequisite tables exist.")


if __name__ == "__main__":
    main()
