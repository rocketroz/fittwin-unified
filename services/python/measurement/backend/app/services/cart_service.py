"""
Cart Service

Handles cart management including adding/updating/removing items,
inventory validation, and cart persistence.
"""

from typing import Dict, List, Optional, Any
from datetime import datetime
from supabase import Client
import os


class CartService:
    """Service for managing shopping carts."""

    MAX_QUANTITY_PER_ITEM = 5
    FREE_SHIPPING_THRESHOLD = 10000  # cents

    def __init__(self, supabase_client: Client):
        """Initialize cart service with Supabase client."""
        self.db = supabase_client

    async def get_cart(self, user_id: str) -> Dict[str, Any]:
        """
        Get the current cart for a user.

        Args:
            user_id: User ID

        Returns:
            Cart with items and totals
        """
        # Get or create cart
        cart = await self._ensure_cart(user_id)

        # Get cart items with product and variant details
        items_response = self.db.table("cart_items")\
            .select("*, products(*), product_variants(*)")\
            .eq("cart_id", cart["id"])\
            .execute()

        items = []
        subtotal = 0

        for item in items_response.data:
            variant = item["product_variants"]
            product = item["products"]

            unit_price = variant["price_cents"]
            line_total = unit_price * item["quantity"]
            subtotal += line_total

            items.append({
                "item_id": item["id"],
                "product_id": product["id"],
                "variant_sku": variant["sku"],
                "name": product["name"],
                "size_label": variant["label"],
                "qty": item["quantity"],
                "unit_price": unit_price,
                "currency": variant["currency"],
                "recommended": item.get("recommended", False),
                "fit_summary": item.get("fit_summary", {})
            })

        # Calculate totals
        tax = int(subtotal * 0.0825)  # 8.25% tax rate
        shipping = 0 if subtotal >= self.FREE_SHIPPING_THRESHOLD else 1200

        return {
            "cart_id": cart["id"],
            "items": items,
            "totals": {
                "subtotal": subtotal,
                "shipping": shipping,
                "tax": tax,
                "total": subtotal + shipping + tax,
                "currency": "USD"
            }
        }

    async def add_item(
        self,
        user_id: str,
        product_id: str,
        variant_sku: str,
        quantity: int = 1,
        recommended: bool = False,
        fit_summary: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Add an item to the cart.

        Args:
            user_id: User ID
            product_id: Product ID
            variant_sku: Variant SKU
            quantity: Quantity to add (1-5)
            recommended: Whether this was a recommended size
            fit_summary: Fit analysis data

        Returns:
            Updated cart item

        Raises:
            ValueError: If quantity is invalid or inventory insufficient
        """
        # Validate quantity
        if quantity <= 0 or quantity > self.MAX_QUANTITY_PER_ITEM:
            raise ValueError(f"Quantity must be between 1 and {self.MAX_QUANTITY_PER_ITEM}")

        # Get variant and check inventory
        variant_response = self.db.table("product_variants")\
            .select("*")\
            .eq("sku", variant_sku)\
            .eq("product_id", product_id)\
            .single()\
            .execute()

        if not variant_response.data:
            raise ValueError("Variant not found")

        variant = variant_response.data

        if variant["stock"] < quantity:
            raise ValueError("Insufficient inventory")

        # Get or create cart
        cart = await self._ensure_cart(user_id)

        # Check if item already exists in cart
        existing_item_response = self.db.table("cart_items")\
            .select("*")\
            .eq("cart_id", cart["id"])\
            .eq("variant_id", variant["id"])\
            .execute()

        if existing_item_response.data:
            # Update existing item
            existing_item = existing_item_response.data[0]
            new_quantity = min(
                existing_item["quantity"] + quantity,
                self.MAX_QUANTITY_PER_ITEM
            )

            updated_item = self.db.table("cart_items")\
                .update({
                    "quantity": new_quantity,
                    "updated_at": datetime.utcnow().isoformat()
                })\
                .eq("id", existing_item["id"])\
                .execute()

            return await self._format_cart_item(updated_item.data[0])
        else:
            # Create new cart item
            new_item = self.db.table("cart_items")\
                .insert({
                    "cart_id": cart["id"],
                    "product_id": product_id,
                    "variant_id": variant["id"],
                    "quantity": quantity,
                    "recommended": recommended,
                    "fit_summary": fit_summary or {}
                })\
                .execute()

            return await self._format_cart_item(new_item.data[0])

    async def update_item(
        self,
        user_id: str,
        item_id: str,
        quantity: Optional[int] = None,
        variant_sku: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Update a cart item.

        Args:
            user_id: User ID
            item_id: Cart item ID
            quantity: New quantity (if None, keep current)
            variant_sku: New variant SKU (if None, keep current)

        Returns:
            Updated cart

        Raises:
            ValueError: If item not found or invalid update
        """
        cart = await self._ensure_cart(user_id)

        # Get cart item
        item_response = self.db.table("cart_items")\
            .select("*")\
            .eq("id", item_id)\
            .eq("cart_id", cart["id"])\
            .single()\
            .execute()

        if not item_response.data:
            raise ValueError("Cart item not found")

        update_data = {"updated_at": datetime.utcnow().isoformat()}

        # Update quantity
        if quantity is not None:
            if quantity <= 0:
                # Remove item if quantity is 0 or negative
                return await self.remove_item(user_id, item_id)
            else:
                update_data["quantity"] = min(quantity, self.MAX_QUANTITY_PER_ITEM)

        # Update variant
        if variant_sku:
            variant_response = self.db.table("product_variants")\
                .select("*")\
                .eq("sku", variant_sku)\
                .single()\
                .execute()

            if not variant_response.data:
                raise ValueError("Variant not found")

            update_data["variant_id"] = variant_response.data["id"]

        # Apply update
        self.db.table("cart_items")\
            .update(update_data)\
            .eq("id", item_id)\
            .execute()

        return await self.get_cart(user_id)

    async def remove_item(self, user_id: str, item_id: str) -> None:
        """
        Remove an item from the cart.

        Args:
            user_id: User ID
            item_id: Cart item ID

        Raises:
            ValueError: If item not found
        """
        cart = await self._ensure_cart(user_id)

        result = self.db.table("cart_items")\
            .delete()\
            .eq("id", item_id)\
            .eq("cart_id", cart["id"])\
            .execute()

        if not result.data:
            raise ValueError("Cart item not found")

    async def clear_cart(self, user_id: str) -> None:
        """
        Clear all items from the cart.

        Args:
            user_id: User ID
        """
        cart = await self._ensure_cart(user_id)

        self.db.table("cart_items")\
            .delete()\
            .eq("cart_id", cart["id"])\
            .execute()

    async def _ensure_cart(self, user_id: str) -> Dict[str, Any]:
        """
        Get or create a cart for the user.

        Args:
            user_id: User ID

        Returns:
            Cart record
        """
        # Try to get existing cart
        cart_response = self.db.table("carts")\
            .select("*")\
            .eq("user_id", user_id)\
            .execute()

        if cart_response.data:
            return cart_response.data[0]

        # Create new cart
        new_cart = self.db.table("carts")\
            .insert({"user_id": user_id})\
            .execute()

        return new_cart.data[0]

    async def _format_cart_item(self, item: Dict[str, Any]) -> Dict[str, Any]:
        """Format a cart item with product and variant details."""
        # Get product and variant details
        variant = self.db.table("product_variants")\
            .select("*")\
            .eq("id", item["variant_id"])\
            .single()\
            .execute().data

        product = self.db.table("products")\
            .select("*")\
            .eq("id", item["product_id"])\
            .single()\
            .execute().data

        return {
            "item_id": item["id"],
            "product_id": product["id"],
            "variant_sku": variant["sku"],
            "name": product["name"],
            "size_label": variant["label"],
            "qty": item["quantity"],
            "unit_price": variant["price_cents"],
            "currency": variant["currency"],
            "recommended": item.get("recommended", False),
            "fit_summary": item.get("fit_summary", {})
        }
