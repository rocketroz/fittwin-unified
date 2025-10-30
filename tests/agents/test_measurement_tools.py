"""
Tests for CrewAI measurement tools.
"""

import pytest
from unittest.mock import Mock, patch
from agents.tools.measurement_tools import (
    validate_measurements,
    recommend_size
)


class TestMeasurementTools:
    """Test measurement tool functions."""

    @patch('agents.tools.measurement_tools.requests.post')
    def test_validate_measurements_tool(self, mock_post):
        """Test measurement validation tool."""
        # Mock API response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "valid": True,
            "measurements_cm": {
                "waist_natural_cm": 81.28,
                "hip_low_cm": 101.6
            }
        }
        mock_post.return_value = mock_response

        # Call the tool
        result = validate_measurements(
            waist_natural=32,
            hip_low=40,
            unit="in"
        )

        assert result["valid"] is True
        assert "measurements_cm" in result

    @patch('agents.tools.measurement_tools.requests.post')
    def test_recommend_size_tool(self, mock_post):
        """Test size recommendation tool."""
        # Mock API response
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "recommended_size": "M",
            "confidence": 0.85,
            "alternatives": ["S", "L"]
        }
        mock_post.return_value = mock_response

        # Call the tool
        result = recommend_size(
            waist_natural_cm=81.28,
            hip_low_cm=101.6,
            chest_cm=101.6
        )

        assert result["recommended_size"] == "M"
        assert result["confidence"] == 0.85
