"""
Validate Looker LookML structure for this project.

Usage:
  python scripts/validate_lookml.py
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOOKER = ROOT / "looker"

REQUIRED_FILES = [
    "constants.lkml",
    "models/churn_intelligence.model.lkml",
    "views/customer_risk.view.lkml",
    "views/dim_customer.view.lkml",
    "views/retention_decision_engine.view.lkml",
    "views/retention_what_if.view.lkml",
    "views/retention_marginal_gain.view.lkml",
    "views/model_champion.view.lkml",
    "views/precision_recall_top10.view.lkml",
    "views/model_metrics_history.view.lkml",
    "views/prediction_distribution.view.lkml",
    "dashboards/executive.dashboard.lookml",
    "dashboards/retention_ops.dashboard.lookml",
    "dashboards/model_monitoring.dashboard.lookml",
    "dashboards/what_if_simulator.dashboard.lookml",
]


def main() -> None:
    errors: list[str] = []
    for rel in REQUIRED_FILES:
        path = LOOKER / rel
        if not path.is_file():
            errors.append(f"Missing: looker/{rel}")

    model = LOOKER / "models/churn_intelligence.model.lkml"
    if model.is_file():
        text = model.read_text(encoding="utf-8")
        for token in ("connection:", "explore: retention_decision_engine", "prediction_distribution", "dashboards/*.dashboard.lookml"):
            if token not in text:
                errors.append(f"Model missing `{token}`")
        if 'connection: "churn_bigquery"' not in text:
            errors.append('Model connection should be "churn_bigquery"')

    constants = LOOKER / "constants.lkml"
    env_path = ROOT / ".env"
    if constants.is_file() and env_path.is_file():
        ctext = constants.read_text(encoding="utf-8")
        env_project = None
        for line in env_path.read_text(encoding="utf-8").splitlines():
            if line.startswith("GCP_PROJECT_ID="):
                env_project = line.split("=", 1)[1].strip().strip('"')
                break
        if env_project and f'value: "{env_project}"' not in ctext:
            errors.append(
                f"constants.lkml BIGQUERY_PROJECT_ID must match .env GCP_PROJECT_ID={env_project}"
            )

    for path in LOOKER.rglob("*.view.lkml"):
        text = path.read_text(encoding="utf-8")
        if "sql_table_name:" not in text:
            errors.append(f"View missing sql_table_name: {path.relative_to(ROOT)}")

    for path in LOOKER.rglob("*.dashboard.lookml"):
        text = path.read_text(encoding="utf-8")
        if "- dashboard:" not in text:
            errors.append(f"Dashboard missing block: {path.relative_to(ROOT)}")
        if "model: churn_intelligence" not in text:
            errors.append(f"Dashboard should use model churn_intelligence: {path.relative_to(ROOT)}")

    if errors:
        print("LOOKML VALIDATION FAILED", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        sys.exit(1)

    print("LOOKML VALIDATION PASSED")
    print(f"  Explores ready: customer_risk, retention_decision_engine, retention_what_if, ...")
    print(f"  Dashboards: executive, retention_ops, model_monitoring, what_if_simulator")
    print(f"  Connection name: churn_bigquery")
    print(f"  Project: check looker/constants.lkml")


if __name__ == "__main__":
    main()
