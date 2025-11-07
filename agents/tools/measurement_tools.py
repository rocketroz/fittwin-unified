"""Compatibility wrapper for CrewAI measurement tools."""

from __future__ import annotations

from typing import Any, Dict

from ai.crewai.tools import measurement_tools as _measurement_tools

_recommend_sizes = _measurement_tools.recommend_sizes
_validate_measurements = _measurement_tools.validate_measurements
requests = _measurement_tools.requests  # noqa: F401 - used by unit tests
CircuitBreaker = _measurement_tools.CircuitBreaker  # re-export for completeness

__all__ = ["validate_measurements", "recommend_sizes", "recommend_size"]


def _normalize_payload(args: tuple[Any, ...], kwargs: Dict[str, Any]) -> Dict[str, Any]:
    """Mirror the old signature where callers could pass kwargs or a dict."""

    if args:
        if len(args) == 1 and isinstance(args[0], dict):
            return args[0]
        raise TypeError("Only a single dict positional argument is supported.")

    return dict(kwargs)


def validate_measurements(*args: Any, **kwargs: Any) -> Dict[str, Any]:
    """Allow kwargs while dispatching to the modern helper."""

    payload = _normalize_payload(args, kwargs)
    return _validate_measurements(payload)


def recommend_sizes(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Direct passthrough for callers already using the plural form."""

    return _recommend_sizes(payload)


def recommend_size(*args: Any, **kwargs: Any) -> Dict[str, Any]:
    """Backwards-compatible alias for the renamed `recommend_sizes` helper."""

    payload = _normalize_payload(args, kwargs)
    return _recommend_sizes(payload)
