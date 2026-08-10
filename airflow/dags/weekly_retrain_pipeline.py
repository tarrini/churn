"""Weekly retrain: BQML + Vertex challenger + metrics."""

from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator

from _repo_paths import DBT_DIR, ML_DIR, SCRIPTS_DIR, SQL_DIR, bash_path

with DAG(
    dag_id="weekly_retrain_pipeline",
    start_date=datetime(2025, 1, 1),
    schedule="@weekly",
    catchup=False,
    tags=["churn", "retrain", "composer"],
    doc_md="Weekly dbt refresh, BQML retrain, Vertex train/eval, monitoring metrics.",
) as dag:
    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"cd {bash_path(DBT_DIR)} && dbt deps && dbt run && dbt test",
    )
    train_bqml = BashOperator(
        task_id="train_bqml",
        bash_command=(
            f"python {bash_path(SCRIPTS_DIR / 'run_sql_folder.py')} "
            f"--folder {bash_path(SQL_DIR / 'bqml')}"
        ),
    )
    train_vertex = BashOperator(
        task_id="train_vertex",
        bash_command=f"python {bash_path(ML_DIR / 'vertex' / 'train_vertex_tabular.py')}",
    )
    evaluate_vertex = BashOperator(
        task_id="evaluate_vertex",
        bash_command=f"python {bash_path(ML_DIR / 'vertex' / 'evaluate_vertex.py')}",
    )
    log_metrics = BashOperator(
        task_id="log_metrics",
        bash_command=(
            f"python {bash_path(SCRIPTS_DIR / 'run_sql_folder.py')} "
            f"--folder {bash_path(SQL_DIR / 'monitoring')}"
        ),
    )

    dbt_build >> train_bqml >> train_vertex >> evaluate_vertex >> log_metrics
