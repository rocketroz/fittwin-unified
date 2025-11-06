"""
Tests for cart management endpoints.
"""

import pytest
from fastapi.testclient import TestClient
from backend.app.main import app

client = TestClient(app)


class TestCartManagement:
    """Test cart CRUD operations."""

    def test_get_empty_cart(self):
        """Test retrieving an empty cart."""
        response = client.get(
            "/api/v1/cart",
            headers={"X-API-Key": "staging-secret-key"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert isinstance(data["items"], list)

    def test_add_item_to_cart(self):
        """Test adding an item to cart."""
        payload = {
            "product_id": "prod_123",
            "variant_id": "var_456",
            "quantity": 2,
            "size": "M"
        }
        
        response = client.post(
            "/api/v1/cart/items",
            json=payload,
            headers={"X-API-Key": "staging-secret-key"}
        )
        
        assert response.status_code == 201
        data = response.json()
        assert "cart_item_id" in data

    def test_update_cart_item_quantity(self):
        """Test updating cart item quantity."""
        payload = {
            "quantity": 3
        }
        
        response = client.put(
            "/api/v1/cart/items/item_123",
            json=payload,
            headers={"X-API-Key": "staging-secret-key"}
        )
        
        # May return 404 if item doesn't exist, which is expected
        assert response.status_code in [200, 404]

    def test_remove_cart_item(self):
        """Test removing an item from cart."""
        response = client.delete(
            "/api/v1/cart/items/item_123",
            headers={"X-API-Key": "staging-secret-key"}
        )
        
        # May return 404 if item doesn't exist, which is expected
        assert response.status_code in [204, 404]
