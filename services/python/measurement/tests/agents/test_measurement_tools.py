"""
Tests for CrewAI measurement tool wrappers.
"""

from __future__ import annotations

from unittest.mock import Mock, patch

from ai.crewai.tools.measurement_tools import recommend_sizes, validate_measurements


@patch("ai.crewai.tools.measurement_tools.requests.post")
def test_validate_measurements_success(mock_post: Mock) -> None:
    payload = {"waist_natural_cm": 81.2, "hip_low_cm": 98.6}

    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json.return_value = {"valid": True, "measurements_cm": payload}
    mock_post.return_value = mock_response

    result = validate_measurements(payload)

    assert result["valid"] is True
    mock_post.assert_called_once()


@patch("ai.crewai.tools.measurement_tools.requests.post")
def test_recommend_sizes_success(mock_post: Mock) -> None:
    payload = {"measurements_cm": {"waist_natural_cm": 81.2}}

    mock_response = Mock()
    mock_response.status_code = 200
    mock_response.json.return_value = {
        "recommended_size": "M",
        "confidence": 0.85,
    }
    mock_post.return_value = mock_response

    result = recommend_sizes(payload)

    assert result["recommended_size"] == "M"
    assert result["confidence"] == 0.85
    mock_post.assert_called_once()
