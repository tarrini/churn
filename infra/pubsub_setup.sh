#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${1:?Usage: ./infra/pubsub_setup.sh <project_id> <region>}"
REGION="${2:-us-central1}"
TOPIC="usage-events-topic"
SUBSCRIPTION="usage-events-sub"
BQ_TABLE="${PROJECT_ID}:raw.usage_events_stream"

gcloud config set project "${PROJECT_ID}"
gcloud pubsub topics create "${TOPIC}" || true
gcloud pubsub subscriptions create "${SUBSCRIPTION}" --topic "${TOPIC}" || true
gcloud pubsub subscriptions create usage-events-bq-sub \
  --topic="${TOPIC}" \
  --bigquery-table="${BQ_TABLE}" \
  --use-table-schema \
  --drop-unknown-fields || true

echo "Pub/Sub setup complete in ${REGION}."
