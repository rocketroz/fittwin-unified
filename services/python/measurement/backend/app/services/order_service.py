"""
Order Service

Handles order creation, lifecycle management, and payment processing.
"""

from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
from enum import Enum
from supabase import Client
import stripe
import os


class OrderStatus(str, Enum):
    """Order status states."""
    CREATED = "created"
    PAID = "paid"
    SENT_TO_BRAND = "sent_to_brand"
    FULFILLED = "fulfilled"
    DELIVERED = "delivered"
    RETURN_REQUESTED = "return_requested"
    CLOSED = "closed"
    CANCELLED = "cancelled"


class OrderService:
    """Service for managing orders."""

    def __init__(self, supabase_client: Client):
        """Initialize order service."""
        self.db = supabase_client
        stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

    async def create_order_from_cart(
        self,
        user_id: str,
        cart_id: str,
        payment_token_id: str,
        shipping_address_id: str,
        billing_address_id: str,
        rid: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create an order from a cart and process payment.

        Args:
            user_id: User ID
            cart_id: Cart ID
            payment_token_id: Stripe payment method ID
            shipping_address_id: Shipping address ID
            billing_address_id: Billing address ID
            rid: Referral ID (optional)

        Returns:
            Order details with payment status

        Raises:
            ValueError: If cart is empty or payment fails
        """
        # Get cart items
        cart_items_response = self.db.table("cart_items")\
            .select("*, product_variants(*), products(*)")\
            .eq("cart_id", cart_id)\
            .execute()

        if not cart_items_response.data:
            raise ValueError("Cart is empty")

        # Calculate totals
        subtotal = 0
        for item in cart_items_response.data:
            variant = item["product_variants"]
            subtotal += variant["price_cents"] * item["quantity"]

        tax = int(subtotal * 0.0825)
        shipping = 0 if subtotal >= 10000 else 1200
        total = subtotal + tax + shipping

        # Create Stripe payment intent
        try:
            payment_intent = stripe.PaymentIntent.create(
                amount=total,
                currency="usd",
                payment_method=payment_token_id,
                confirm=True,
                metadata={
                    "user_id": user_id,
                    "cart_id": cart_id,
                    "rid": rid or ""
                }
            )
        except stripe.error.StripeError as e:
            raise ValueError(f"Payment failed: {str(e)}")

        # Create order
        order_data = {
            "user_id": user_id,
            "status": OrderStatus.PAID.value,
            "subtotal_cents": subtotal,
            "tax_cents": tax,
            "shipping_cents": shipping,
            "total_cents": total,
            "currency": "USD",
            "shipping_address_id": shipping_address_id,
            "billing_address_id": billing_address_id,
            "payment_intent_id": payment_intent.id,
            "rid": rid
        }

        order_response = self.db.table("orders")\
            .insert(order_data)\
            .execute()

        order = order_response.data[0]

        # Create order items from cart items
        order_items = []
        for cart_item in cart_items_response.data:
            variant = cart_item["product_variants"]
            product = cart_item["products"]

            order_item = {
                "order_id": order["id"],
                "product_id": product["id"],
                "variant_id": variant["id"],
                "quantity": cart_item["quantity"],
                "unit_price_cents": variant["price_cents"],
                "currency": variant["currency"],
                "recommended": cart_item.get("recommended", False),
                "fit_summary": cart_item.get("fit_summary", {})
            }
            order_items.append(order_item)

        self.db.table("order_items")\
            .insert(order_items)\
            .execute()

        # Clear cart
        self.db.table("cart_items")\
            .delete()\
            .eq("cart_id", cart_id)\
            .execute()

        # Track referral attribution if RID provided
        if rid:
            await self._track_referral_conversion(rid, order["id"], total)

        return {
            "order_id": order["id"],
            "status": order["status"],
            "payment_intent_ref": payment_intent.id,
            "total": total,
            "currency": "USD",
            "next": {
                "tracking": None,
                "brand_fulfillment_eta": (datetime.utcnow() + timedelta(days=5)).date().isoformat()
            }
        }

    async def get_order(self, user_id: str, order_id: str) -> Dict[str, Any]:
        """
        Get order details.

        Args:
            user_id: User ID
            order_id: Order ID

        Returns:
            Order with items

        Raises:
            ValueError: If order not found
        """
        order_response = self.db.table("orders")\
            .select("*")\
            .eq("id", order_id)\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not order_response.data:
            raise ValueError("Order not found")

        order = order_response.data

        # Get order items
        items_response = self.db.table("order_items")\
            .select("*, products(*), product_variants(*)")\
            .eq("order_id", order_id)\
            .execute()

        items = []
        for item in items_response.data:
            variant = item["product_variants"]
            product = item["products"]

            items.append({
                "product_id": product["id"],
                "name": product["name"],
                "variant_sku": variant["sku"],
                "size_label": variant["label"],
                "quantity": item["quantity"],
                "unit_price": item["unit_price_cents"],
                "currency": item["currency"]
            })

        return {
            "order_id": order["id"],
            "status": order["status"],
            "created_at": order["created_at"],
            "items": items,
            "totals": {
                "subtotal": order["subtotal_cents"],
                "tax": order["tax_cents"],
                "shipping": order["shipping_cents"],
                "total": order["total_cents"],
                "currency": order["currency"]
            },
            "tracking": order.get("tracking_number"),
            "estimated_delivery": order.get("estimated_delivery_date")
        }

    async def list_orders(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        List user's orders.

        Args:
            user_id: User ID
            limit: Maximum number of orders to return
            offset: Offset for pagination

        Returns:
            List of orders
        """
        orders_response = self.db.table("orders")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)\
            .execute()

        return orders_response.data

    async def cancel_order(self, user_id: str, order_id: str) -> Dict[str, Any]:
        """
        Cancel an order.

        Args:
            user_id: User ID
            order_id: Order ID

        Returns:
            Updated order

        Raises:
            ValueError: If order cannot be cancelled
        """
        order_response = self.db.table("orders")\
            .select("*")\
            .eq("id", order_id)\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not order_response.data:
            raise ValueError("Order not found")

        order = order_response.data

        # Only allow cancellation for certain statuses
        cancellable_statuses = [OrderStatus.CREATED.value, OrderStatus.PAID.value]
        if order["status"] not in cancellable_statuses:
            raise ValueError(f"Order cannot be cancelled in status: {order['status']}")

        # Refund payment if already paid
        if order["status"] == OrderStatus.PAID.value and order.get("payment_intent_id"):
            try:
                stripe.Refund.create(
                    payment_intent=order["payment_intent_id"]
                )
            except stripe.error.StripeError as e:
                raise ValueError(f"Refund failed: {str(e)}")

        # Update order status
        updated_order = self.db.table("orders")\
            .update({
                "status": OrderStatus.CANCELLED.value,
                "updated_at": datetime.utcnow().isoformat()
            })\
            .eq("id", order_id)\
            .execute()

        return updated_order.data[0]

    async def update_order_status(
        self,
        order_id: str,
        status: OrderStatus,
        tracking_number: Optional[str] = None,
        estimated_delivery_date: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Update order status (admin/brand operation).

        Args:
            order_id: Order ID
            status: New status
            tracking_number: Tracking number (optional)
            estimated_delivery_date: Estimated delivery date (optional)

        Returns:
            Updated order
        """
        update_data = {
            "status": status.value,
            "updated_at": datetime.utcnow().isoformat()
        }

        if tracking_number:
            update_data["tracking_number"] = tracking_number

        if estimated_delivery_date:
            update_data["estimated_delivery_date"] = estimated_delivery_date

        updated_order = self.db.table("orders")\
            .update(update_data)\
            .eq("id", order_id)\
            .execute()

        return updated_order.data[0]

    async def _track_referral_conversion(
        self,
        rid: str,
        order_id: str,
        amount_cents: int
    ) -> None:
        """Track referral conversion event."""
        self.db.table("referral_events")\
            .insert({
                "rid": rid,
                "event_type": "conversion",
                "order_id": order_id,
                "amount_cents": amount_cents,
                "metadata": {}
            })\
            .execute()
