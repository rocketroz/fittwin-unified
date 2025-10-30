"""
Cart management router for FitTwin Platform.

Adapted from fittwindev/fittwin cart.service.ts
Provides cart operations: add, update, remove items, and checkout.
"""

from typing import Dict, Any, List
from fastapi import APIRouter, Header, HTTPException, status
from pydantic import BaseModel, Field

from app.core.config import settings
from app.schemas.errors import ErrorResponse

router = APIRouter(prefix="/cart", tags=["cart"])


# Pydantic Models
class AddItemRequest(BaseModel):
    product_id: str = Field(..., description="Product ID")
    variant_sku: str = Field(..., description="Variant SKU")
    qty: int = Field(1, ge=1, le=5, description="Quantity (1-5)")
    source: str | None = Field(None, description="Source of add (e.g., 'tryon', 'pdp')")


class UpdateItemRequest(BaseModel):
    qty: int | None = Field(None, ge=0, le=5, description="New quantity (0 to remove)")
    variant_sku: str | None = Field(None, description="New variant SKU")


class CheckoutRequest(BaseModel):
    cart_id: str | None = Field(None, description="Cart ID (optional, uses session cart if not provided)")
    payment_token_id: str = Field(..., description="Payment method token ID")
    shipping_address_id: str = Field(..., description="Shipping address ID")
    billing_address_id: str = Field(..., description="Billing address ID")
    rid: str | None = Field(None, description="Referral ID for attribution")
    idempotency_key: str | None = Field(None, description="Idempotency key to prevent double charges")


class CartItemResponse(BaseModel):
    item_id: str
    product_id: str
    variant_sku: str
    name: str
    size_label: str
    qty: int
    unit_price: int  # in cents
    currency: str
    recommended: bool
    fit_summary: Dict[str, Any]


class CartResponse(BaseModel):
    cart_id: str
    items: List[CartItemResponse]
    totals: Dict[str, Any]
    recommendations: List[Dict[str, Any]]


class CheckoutResponse(BaseModel):
    order_id: str
    status: str
    payment_intent_ref: str
    next: Dict[str, Any]


# TODO: Replace with actual database/service layer
# This is a placeholder implementation
MOCK_CART = {
    "cart_id": "cart-demo-123",
    "items": [],
    "totals": {
        "subtotal": 0,
        "shipping": 0,
        "tax": 0,
        "currency": "USD"
    },
    "recommendations": []
}


@router.get("", response_model=CartResponse)
async def get_cart(
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    Get the current user's cart.
    
    Returns cart items, totals, and size recommendations.
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual cart retrieval from database
    # For now, return mock cart
    return CartResponse(**MOCK_CART)


@router.post("/items", status_code=status.HTTP_201_CREATED)
async def add_cart_item(
    request: AddItemRequest,
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    Add an item to the cart.
    
    Validates inventory and enforces quantity limits.
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual cart item addition
    # 1. Validate product and variant exist
    # 2. Check inventory availability
    # 3. Add to cart or update existing item
    # 4. Return updated cart item
    
    return {
        "cart_id": "cart-demo-123",
        "item_id": "item-demo-456",
        "item": {
            "product_id": request.product_id,
            "variant_sku": request.variant_sku,
            "name": "Demo Product",
            "size_label": "M",
            "qty": request.qty,
            "unit_price": 4200,
            "currency": "USD",
            "recommended": True,
            "fit_summary": {"confidence": 88, "notes": ["waist snug"]}
        }
    }


@router.put("/items/{item_id}")
async def update_cart_item(
    item_id: str,
    request: UpdateItemRequest,
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    Update a cart item's quantity or variant.
    
    Set qty to 0 to remove the item.
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual cart item update
    # 1. Find cart item by ID
    # 2. Update quantity or variant
    # 3. If qty is 0, remove item
    # 4. Return updated cart
    
    return CartResponse(**MOCK_CART)


@router.delete("/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_cart_item(
    item_id: str,
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    Remove an item from the cart.
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual cart item removal
    # 1. Find cart item by ID
    # 2. Remove from cart
    # 3. Return 204 No Content
    
    return None


@router.post("/checkout", response_model=CheckoutResponse)
async def checkout(
    request: CheckoutRequest,
    x_api_key: str = Header(..., description="API key for authentication")
):
    """
    Complete checkout and create an order.
    
    Validates payment method, addresses, and inventory.
    Uses idempotency key to prevent double charges.
    """
    if x_api_key != settings.api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=ErrorResponse(
                error={"code": "UNAUTHORIZED", "message": "Invalid API key"}
            ).dict()
        )
    
    # TODO: Implement actual checkout flow
    # 1. Validate cart is not empty
    # 2. Check idempotency key for duplicate requests
    # 3. Validate payment token and addresses
    # 4. Create order with status 'created'
    # 5. Process payment via PSP (Stripe)
    # 6. Update order status to 'paid'
    # 7. Attribute to referral if RID provided
    # 8. Clear cart
    # 9. Return order details
    
    return CheckoutResponse(
        order_id="order-demo-789",
        status="paid",
        payment_intent_ref="pi_demo_123456",
        next={
            "tracking": None,
            "brand_fulfillment_eta": "2025-11-05"
        }
    )
