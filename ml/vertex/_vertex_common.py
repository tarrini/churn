"""Shared Vertex helpers: resolve trained model resource name."""

from __future__ import annotations

import os
from pathlib import Path

LAST_MODEL_FILENAME = "last_vertex_model.resource_name"


def last_model_path() -> Path:
    return Path(__file__).resolve().parent / LAST_MODEL_FILENAME


def resolve_model_resource_name(cli_override: str | None) -> str:
    """
    Prefer CLI --model-resource-name, then VERTEX_MODEL_RESOURCE_NAME env,
    then first line of last_vertex_model.resource_name (written by train_vertex_tabular).
    """
    if cli_override and cli_override.strip():
        return cli_override.strip()

    env_name = os.getenv("VERTEX_MODEL_RESOURCE_NAME", "").strip()
    if env_name:
        return env_name

    p = last_model_path()
    if p.is_file():
        line = p.read_text(encoding="utf-8").splitlines()[0].strip()
        if line:
            return line

    raise SystemExit(
        "Missing Vertex model reference. Train first (writes "
        f"{LAST_MODEL_FILENAME}) or set VERTEX_MODEL_RESOURCE_NAME or pass "
        "--model-resource-name with the trained model resource name "
        '(e.g. "projects/.../locations/.../models/...").'
    )
