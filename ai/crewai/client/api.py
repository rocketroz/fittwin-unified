"""Small client helpers for CrewAI agents."""

from __future__ import annotations

import os
from typing import Any, Dict

import httpx


BASE_URL = os.getenv("FITWIN_API_URL", "http://127.0.0.1:8000")


def dmaas_latest() -> Dict[str, Any]:
    """Fetch the latest /dmaas/latest snapshot from the FastAPI service."""

    with httpx.Client(timeout=10.0) as client:
        response = client.get(f"{BASE_URL}/dmaas/latest")
        response.raise_for_status()
        return response.json()
