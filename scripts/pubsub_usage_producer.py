"""
Publish sample usage events to Pub/Sub topic usage-events-topic.

Prereqs:
  - Topic + BigQuery subscription created
  - Table raw.usage_events_stream exists
  - GOOGLE_APPLICATION_CREDENTIALS and GCP_PROJECT_ID set
"""

from __future__ import annotations

import csv
import json
import os
import random
import time
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import pubsub_v1

ROOT = Path(__file__).resolve().parent.parent
load_dotenv(ROOT / ".env")

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
TOPIC_ID = os.getenv("PUBSUB_TOPIC", "usage-events-topic")
RAW_CSV_DIR = Path(os.getenv("BQ_RAW_CSV_DIR", "data/raw"))
if not RAW_CSV_DIR.is_absolute():
    RAW_CSV_DIR = ROOT / RAW_CSV_DIR

if not PROJECT_ID:
    raise SystemExit("Set GCP_PROJECT_ID in .env")

publisher = pubsub_v1.PublisherClient()
topic_path = publisher.topic_path(PROJECT_ID, TOPIC_ID)
EVENT_TYPES = ["login", "api_call", "feature_use", "export"]


def load_customer_ids() -> list[str]:
    for path in (
        RAW_CSV_DIR / "telco_customer_churn.csv",
        RAW_CSV_DIR / "WA_Fn-UseC_-Telco-Customer-Churn.csv",
    ):
        if not path.exists():
            continue
        with path.open(newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            if not reader.fieldnames or "customerID" not in reader.fieldnames:
                break
            ids = [row["customerID"].strip() for row in reader if row.get("customerID")]
            if ids:
                return ids
    return [f"C{i:05d}" for i in range(1, 501)]


def make_event(i: int, customer_ids: list[str]) -> dict:
    return {
        "event_id": f"PE{i:010d}",
        "customer_id": random.choice(customer_ids),
        "event_ts": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S"),
        "event_type": random.choice(EVENT_TYPES),
    }


def main() -> None:
    customer_ids = load_customer_ids()
    print(f"Publishing to {topic_path}")
    print("Ctrl+C to stop")
    i = 1
    while True:
        event = make_event(i, customer_ids)
        data = json.dumps(event).encode("utf-8")
        future = publisher.publish(topic_path, data)
        future.result()
        print(f"Published {event}")
        i += 1
        time.sleep(1)


if __name__ == "__main__":
    main()
