# Cloud Composer (daily / weekly automation)

Composer runs Airflow in GCP so pipelines schedule themselves.

## Cost warning
Composer is one of the more expensive GCP services. Use a **small** environment and delete it when you are done demos if you want to save credits.

## What gets scheduled

| DAG | Schedule | Steps |
|-----|----------|--------|
| `daily_churn_pipeline` | Daily | dbt → BQML SQL → monitoring → serving |
| `weekly_retrain_pipeline` | Weekly | dbt → BQML → Vertex train/eval → monitoring |

Cloud Run stays as the **API**. Composer is the **scheduler**.

## 1) Create environment (project owner account)

```powershell
cd C:\Users\praka\churn-intelligence-gcp
gcloud.cmd config set account prakashmathan52@gmail.com
gcloud.cmd config set project churn-499415

gcloud.cmd services enable composer.googleapis.com storage.googleapis.com

gcloud.cmd composer environments create churn-composer `
  --location=us-central1 `
  --image-version=composer-2-airflow-2.9.3-build.5 `
  --environment-size=small `
  --async
```

Wait until status is **RUNNING** (often 20–40 minutes):

```powershell
gcloud.cmd composer environments describe churn-composer --location=us-central1
```

## 2) Sync DAGs + project code

```powershell
$DAG_BUCKET = gcloud.cmd composer environments describe churn-composer --location=us-central1 --format="value(config.dagGcsPrefix)"
# Example result: gs://.../dags  → upload into that prefix's parent

# Resolve bucket root (strip /dags)
$BAG = ($DAG_BUCKET -replace "/dags$","")
echo $BAG

gsutil.cmd -m rsync -r airflow/dags "$BAG/dags"
gsutil.cmd -m rsync -r dbt "$BAG/dags/dbt"
gsutil.cmd -m rsync -r sql "$BAG/dags/sql"
gsutil.cmd -m rsync -r scripts "$BAG/dags/scripts"
gsutil.cmd -m rsync -r ml "$BAG/dags/ml"
```

## 3) Env vars + PyPI packages on Composer

```powershell
gcloud.cmd composer environments update churn-composer `
  --location=us-central1 `
  --update-env-variables="CHURN_REPO_ROOT=/home/airflow/gcs/dags,GCP_PROJECT_ID=churn-499415,GCP_LOCATION=US,GCS_VERTEX_STAGING_BUCKET=gs://churn-499415-vertex-staging"

gcloud.cmd composer environments update churn-composer `
  --location=us-central1 `
  --update-pypi-packages-from-file=airflow/requirements-composer.txt
```

Also upload `dbt/profiles.yml` expectations: Composer workers need a service account that can run BigQuery. The Composer environment SA usually needs:
- BigQuery Job User / Data Editor
- Vertex AI User (for weekly DAG)
- Storage Object Admin on staging bucket

## 4) Open Airflow UI and test

```powershell
gcloud.cmd composer environments describe churn-composer --location=us-central1 --format="value(config.airflowUri)"
```

In the UI:
1. Find `daily_churn_pipeline`
2. **Trigger** once manually
3. Confirm tasks go green
4. Leave schedule `@daily` enabled for automatic runs

## 5) Screenshot
- Composer environment RUNNING
- Airflow UI with both DAGs
- One successful `daily_churn_pipeline` run graph
