import argparse
import os
import re

from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv()
PROJECT_ID = os.getenv("GCP_PROJECT_ID")
client = bigquery.Client(project=PROJECT_ID)


def render_sql(sql_text: str) -> str:
    return re.sub(r"\{\{PROJECT_ID\}\}", PROJECT_ID, sql_text)


def run_sql_file(path: str) -> None:
    with open(path, "r", encoding="utf-8") as f:
        sql = render_sql(f.read())
    job = client.query(sql)
    job.result()
    print(f"Executed: {path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--folder", required=True, help="Folder containing .sql files")
    args = parser.parse_args()
    sql_files = sorted([f for f in os.listdir(args.folder) if f.endswith(".sql")])
    for sql_file in sql_files:
        run_sql_file(os.path.join(args.folder, sql_file))


if __name__ == "__main__":
    main()
