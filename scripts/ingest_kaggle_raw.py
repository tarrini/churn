from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import zipfile
from pathlib import Path

from dotenv import load_dotenv

_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(_ROOT / ".env")


def _dataset_slug_from_env() -> str:
    a = (os.getenv("KAGGLE_DATASET") or "").strip()
    return a 


DEFAULT_SLUG = _dataset_slug_from_env()
DEFAULT_FILENAME = os.getenv(
    "KAGGLE_TELCO_CSV_FILENAME", "WA_Fn-UseC_-Telco-Customer-Churn.csv"
)
OUTPUT_CSV = "telco_customer_churn.csv"


def run_command(cmd: list[str]) -> None:
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(
            f"Command failed: {' '.join(cmd)}\nstdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )


def clean_raw_dir(raw_dir: Path) -> None:
    raw_dir.mkdir(parents=True, exist_ok=True)
    for f in raw_dir.glob("*"):
        if f.is_file():
            f.unlink()


def find_csv(search_dir: Path, preferred_name: str) -> Path:
    hits = list(search_dir.rglob("*.csv"))
    if not hits:
        raise FileNotFoundError(f"No CSV files under {search_dir}")
    for p in hits:
        if p.name == preferred_name:
            return p
    return hits[0]


def download_and_extract_kaggle_dataset(raw_dir: Path, dataset_slug: str) -> Path:
    cmd = [
        "kaggle",
        "datasets",
        "download",
        "-d",
        dataset_slug,
        "-p",
        str(raw_dir),
    ]
    print(f"Running: {' '.join(cmd)}")
    run_command(cmd)
    zips = list(raw_dir.glob("*.zip"))
    if not zips:
        raise FileNotFoundError(f"No zip file found in {raw_dir} after kaggle download.")
    zips.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    zip_path = zips[0]
    with zipfile.ZipFile(zip_path, "r") as zf:
        zf.extractall(raw_dir)
    zip_path.unlink(missing_ok=True)
    return find_csv(raw_dir, DEFAULT_FILENAME)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Download Telco churn CSV from Kaggle (single raw landing file)."
    )
    parser.add_argument("--output-dir", default="data/raw", help="Folder for telco_customer_churn.csv")
    parser.add_argument("--slug", default=DEFAULT_SLUG, help="Kaggle dataset slug owner/name")
    args = parser.parse_args()

    kaggle_json = Path.home() / ".kaggle" / "kaggle.json"
    has_env_creds = bool(os.getenv("KAGGLE_USERNAME") and os.getenv("KAGGLE_KEY"))
    if not kaggle_json.is_file() and not has_env_creds:
        raise SystemExit(
            "Kaggle credentials not found. Set KAGGLE_USERNAME and KAGGLE_KEY in .env, or place "
            f"kaggle.json at {kaggle_json}"
        )

    out = Path(args.output_dir)
    print("1. Cleaning output directory")
    clean_raw_dir(out)

    print("2. Downloading dataset from Kaggle (kaggle CLI)")
    csv_path = download_and_extract_kaggle_dataset(out, args.slug)
    print(f"   Extracted CSV: {csv_path}")

    dest = out / OUTPUT_CSV
    shutil.copy2(csv_path, dest)
    print(f"3. Saved single landing file for BigQuery load: {dest.resolve()}")
    print("   Run: python scripts/load_raw_to_bq.py  →  raw.telco_customer_churn")
    print("   Then: cd dbt && dbt run && dbt test  →  staging from SQL")


if __name__ == "__main__":
    main()
