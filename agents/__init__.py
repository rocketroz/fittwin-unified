"""
Compatibility shims for legacy `agents` imports.

Source files now live under `ai.crewai`, but several scripts and tests still
reference the historical `agents.*` modules.  Keeping this package as a thin
proxy avoids touching the downstream call sites during the transition.
"""

from importlib import import_module
from typing import Any


def __getattr__(name: str) -> Any:
    """Proxy attribute lookups to the modern `ai.crewai` namespace."""

    try:
        module = import_module(f"ai.crewai.{name}")
    except ModuleNotFoundError as exc:  # pragma: no cover - pass through original error
        raise AttributeError(f"module 'agents' has no attribute '{name}'") from exc
    return module


__all__ = []  # explicit namespace; populated dynamically via __getattr__
