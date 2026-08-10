import argparse
import os
import re
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery

_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(_ROOT / ".env")


def _resolve_credentials_path() -> None:
    """Relative GOOGLE_APPLICATION_CREDENTIALS in .env is resolved from repo root, not CWD."""
    raw = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if not raw:
        return
    p = Path(raw.strip().strip('"'))
    if not p.is_absolute():
        p = (_ROOT / p).resolve()
    else:
        p = p.resolve()
    if not p.is_file():
        os.environ.pop("GOOGLE_APPLICATION_CREDENTIALS", None)
        print(
            f"Warning: service account JSON not found at {p}; "
            "using Application Default Credentials instead."
        )
        return
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(p)


_resolve_credentials_path()

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
    folder = Path(args.folder)
    if not folder.is_absolute():
        folder = (_ROOT / folder).resolve()
    sql_files = sorted(p for p in folder.iterdir() if p.suffix == ".sql")
    for sql_file in sql_files:
        run_sql_file(str(sql_file))


if __name__ == "__main__":
    main()
