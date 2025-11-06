"""
Tests for measurement validation and recommendation endpoints.
"""

import pytest
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)


class TestMeasurementValidation:
    """Test measurement validation endpoint."""

    def test_validate_measurements_success(self):
        """Test successful measurement validation."""
        payload = {
            "waist_natural": 32,
            "hip_low": 40,
            "unit": "in",
            "session_id": "test-123"
        }
        
        response = client.post(
            "/api/v1/measurements/validate",
            json=payload,
            headers={"X-API-Key": "staging-secret-key"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "valid" in data
        assert "measurements_cm" in data

    def test_validate_measurements_missing_api_key(self):
        """Test validation fails without API key."""
        payload = {
            "waist_natural": 32,
            "hip_low": 40,
            "unit": "in"
        }
        
        response = client.post(
            "/api/v1/measurements/validate",
            json=payload
        )
        
        assert response.status_code == 403


class TestSizeRecommendation:
    """Test size recommendation endpoint."""

    def test_recommend_size_success(self):
        """Test successful size recommendation."""
        payload = {
            "waist_natural_cm": 81.28,
            "hip_low_cm": 101.6,
            "chest_cm": 101.6,
            "model_version": "v1.0-mediapipe"
        }
        
        response = client.post(
            "/api/v1/measurements/recommend",
            json=payload,
            headers={"X-API-Key": "staging-secret-key"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "recommended_size" in data
        assert "confidence" in data
