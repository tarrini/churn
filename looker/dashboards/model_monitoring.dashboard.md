# Model Monitoring Dashboard

- **Champion:** `model_champion` (BQML vs Vertex AUC and related metrics)
- **AUC** over time from `model_metrics_history` (filter by `model_name`)
- **Precision@10 / recall@10** from `precision_recall_top10_daily` (or expose as a derived view)
- **Score distribution drift** from `prediction_distribution_history` (compare `snapshot_date`)
