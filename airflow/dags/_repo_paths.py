"""Shared paths for Airflow DAGs (Composer DAG bucket or local)."""

from __future__ import annotations

import os
from pathlib import Path

# On Composer, code is synced under /home/airflow/gcs/dags
REPO_ROOT = Path(os.environ.get("CHURN_REPO_ROOT", "/home/airflow/gcs/dags"))
DBT_DIR = REPO_ROOT / "dbt"
SQL_DIR = REPO_ROOT / "sql"
SCRIPTS_DIR = REPO_ROOT / "scripts"
ML_DIR = REPO_ROOT / "ml"


def bash_path(path: Path) -> str:
    return str(path).replace("\\", "/")
