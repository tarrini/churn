"""
Cloud Run — Churn Intelligence API
==================================

Deploy (from repo root, as project owner):

  gcloud.cmd config set project churn-499415
  gcloud.cmd services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com

  gcloud.cmd run deploy churn-intelligence-api `
    --source=services/churn_api `
    --region=us-central1 `
    --allow-unauthenticated `
    --set-env-vars="GCP_PROJECT_ID=churn-499415,BQ_MART_DATASET=mart,BQ_ML_DATASET=ml,BQ_MONITORING_DATASET=monitoring" `
    --memory=512Mi

Test:

  curl.exe https://YOUR_URL/health
  curl.exe https://YOUR_URL/interventions/today?limit=5
"""
