import os
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery

_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(_ROOT / ".env")

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
RAW_DATASET = os.getenv("BQ_RAW_DATASET", "raw")
RAW_CSV_DIR = Path(os.getenv("BQ_RAW_CSV_DIR", "data/raw"))

TABLE_FILE_MAP = {
    "telco_customer_churn": "telco_customer_churn.csv",
}


def main():
    client = bigquery.Client(project=PROJECT_ID)
    for table_name, filename in TABLE_FILE_MAP.items():
        path = RAW_CSV_DIR / filename
        if not path.exists():
            print(f"Skipping missing file: {path}")
            continue
        table_id = f"{PROJECT_ID}.{RAW_DATASET}.{table_name}"
        config = bigquery.LoadJobConfig(
            source_format=bigquery.SourceFormat.CSV,
            skip_leading_rows=1,
            autodetect=True,
            write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        )
        with path.open("rb") as source:
            job = client.load_table_from_file(source, table_id, job_config=config)
        job.result()
        print(f"Loaded {path} -> {table_id}")


if __name__ == "__main__":
    main()
