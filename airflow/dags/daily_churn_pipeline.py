"""Daily scoring + serving pipeline for Cloud Composer / Airflow."""

from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator

from _repo_paths import DBT_DIR, SCRIPTS_DIR, SQL_DIR, bash_path

with DAG(
    dag_id="daily_churn_pipeline",
    start_date=datetime(2025, 1, 1),
    schedule="@daily",
    catchup=False,
    tags=["churn", "daily", "composer"],
    doc_md="Daily dbt refresh, BQML predict, monitoring, and retention serving.",
) as dag:
    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"cd {bash_path(DBT_DIR)} && dbt deps && dbt run && dbt test",
    )
    bqml_predict = BashOperator(
        task_id="bqml_predict",
        bash_command=(
            f"python {bash_path(SCRIPTS_DIR / 'run_sql_folder.py')} "
            f"--folder {bash_path(SQL_DIR / 'bqml')}"
        ),
    )
    monitoring = BashOperator(
        task_id="monitoring",
        bash_command=(
            f"python {bash_path(SCRIPTS_DIR / 'run_sql_folder.py')} "
            f"--folder {bash_path(SQL_DIR / 'monitoring')}"
        ),
    )
    serving = BashOperator(
        task_id="serving",
        bash_command=(
            f"python {bash_path(SCRIPTS_DIR / 'run_sql_folder.py')} "
            f"--folder {bash_path(SQL_DIR / 'serving')}"
        ),
    )

    dbt_build >> bqml_predict >> monitoring >> serving
