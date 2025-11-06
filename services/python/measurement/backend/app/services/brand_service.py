"""
Brand Service

Handles brand onboarding, catalog management, and B2B portal operations.
"""

from typing import Dict, List, Optional, Any
from datetime import datetime
import csv
import io
from supabase import Client


class BrandService:
    """Service for managing brand operations."""

    def __init__(self, supabase_client: Client):
        """Initialize brand service."""
        self.db = supabase_client

    async def create_brand(
        self,
        name: str,
        slug: str,
        admin_user_id: str,
        description: Optional[str] = None,
        website_url: Optional[str] = None,
        logo_url: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a new brand.

        Args:
            name: Brand name
            slug: URL-friendly slug
            admin_user_id: User ID of brand admin
            description: Brand description
            website_url: Brand website URL
            logo_url: Brand logo URL

        Returns:
            Created brand

        Raises:
            ValueError: If slug already exists
        """
        # Check if slug already exists
        existing_brand = self.db.table("brands")\
            .select("id")\
            .eq("slug", slug)\
            .execute()

        if existing_brand.data:
            raise ValueError(f"Brand slug '{slug}' already exists")

        # Create brand
        brand_data = {
            "name": name,
            "slug": slug,
            "description": description,
            "website_url": website_url,
            "logo_url": logo_url,
            "onboarded": False,
            "status": "pending"
        }

        brand_response = self.db.table("brands")\
            .insert(brand_data)\
            .execute()

        brand = brand_response.data[0]

        # Assign admin role to user
        await self._assign_brand_admin(brand["id"], admin_user_id)

        return brand

    async def get_brand(self, brand_id: str) -> Dict[str, Any]:
        """
        Get brand details.

        Args:
            brand_id: Brand ID

        Returns:
            Brand details

        Raises:
            ValueError: If brand not found
        """
        brand_response = self.db.table("brands")\
            .select("*")\
            .eq("id", brand_id)\
            .single()\
            .execute()

        if not brand_response.data:
            raise ValueError("Brand not found")

        return brand_response.data

    async def update_brand(
        self,
        brand_id: str,
        **updates
    ) -> Dict[str, Any]:
        """
        Update brand details.

        Args:
            brand_id: Brand ID
            **updates: Fields to update

        Returns:
            Updated brand
        """
        updates["updated_at"] = datetime.utcnow().isoformat()

        updated_brand = self.db.table("brands")\
            .update(updates)\
            .eq("id", brand_id)\
            .execute()

        return updated_brand.data[0]

    async def complete_onboarding(self, brand_id: str) -> Dict[str, Any]:
        """
        Mark brand onboarding as complete.

        Args:
            brand_id: Brand ID

        Returns:
            Updated brand
        """
        return await self.update_brand(
            brand_id,
            onboarded=True,
            status="active"
        )

    async def upload_catalog_csv(
        self,
        brand_id: str,
        csv_content: str
    ) -> Dict[str, Any]:
        """
        Upload product catalog via CSV.

        Expected CSV format:
        sku,name,description,category,price,currency,stock,size,chest_cm,waist_cm,hip_cm

        Args:
            brand_id: Brand ID
            csv_content: CSV file content as string

        Returns:
            Import results

        Raises:
            ValueError: If CSV is invalid
        """
        # Parse CSV
        csv_file = io.StringIO(csv_content)
        reader = csv.DictReader(csv_file)

        products_created = 0
        variants_created = 0
        errors = []

        # Group variants by product
        products_map = {}

        for row_num, row in enumerate(reader, start=2):
            try:
                # Extract product info
                product_key = row["name"].strip()

                if product_key not in products_map:
                    # Create product
                    product_data = {
                        "brand_id": brand_id,
                        "name": row["name"].strip(),
                        "description": row.get("description", "").strip(),
                        "category": row.get("category", "").strip(),
                        "active": True
                    }

                    product_response = self.db.table("products")\
                        .insert(product_data)\
                        .execute()

                    product = product_response.data[0]
                    products_map[product_key] = product["id"]
                    products_created += 1

                product_id = products_map[product_key]

                # Create variant
                variant_data = {
                    "product_id": product_id,
                    "sku": row["sku"].strip(),
                    "label": row["size"].strip(),
                    "price_cents": int(float(row["price"]) * 100),
                    "currency": row.get("currency", "USD").strip().upper(),
                    "stock": int(row["stock"]),
                    "attributes": {
                        "chest_cm": float(row.get("chest_cm", 0)) if row.get("chest_cm") else None,
                        "waist_cm": float(row.get("waist_cm", 0)) if row.get("waist_cm") else None,
                        "hip_cm": float(row.get("hip_cm", 0)) if row.get("hip_cm") else None
                    }
                }

                self.db.table("product_variants")\
                    .insert(variant_data)\
                    .execute()

                variants_created += 1

            except Exception as e:
                errors.append({
                    "row": row_num,
                    "error": str(e)
                })

        return {
            "success": len(errors) == 0,
            "products_created": products_created,
            "variants_created": variants_created,
            "errors": errors
        }

    async def get_brand_products(
        self,
        brand_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get products for a brand.

        Args:
            brand_id: Brand ID
            limit: Maximum number of products to return
            offset: Offset for pagination

        Returns:
            List of products with variants
        """
        products_response = self.db.table("products")\
            .select("*, product_variants(*)")\
            .eq("brand_id", brand_id)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)\
            .execute()

        return products_response.data

    async def get_brand_orders(
        self,
        brand_id: str,
        status: Optional[str] = None,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get orders for a brand.

        Args:
            brand_id: Brand ID
            status: Filter by order status (optional)
            limit: Maximum number of orders to return
            offset: Offset for pagination

        Returns:
            List of orders
        """
        # Get products for this brand
        products_response = self.db.table("products")\
            .select("id")\
            .eq("brand_id", brand_id)\
            .execute()

        product_ids = [p["id"] for p in products_response.data]

        if not product_ids:
            return []

        # Get orders containing these products
        query = self.db.table("orders")\
            .select("*, order_items!inner(product_id)")\
            .in_("order_items.product_id", product_ids)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)

        if status:
            query = query.eq("status", status)

        orders_response = query.execute()

        return orders_response.data

    async def get_brand_analytics(self, brand_id: str) -> Dict[str, Any]:
        """
        Get analytics for a brand.

        Args:
            brand_id: Brand ID

        Returns:
            Analytics data
        """
        # Get total products
        products_response = self.db.table("products")\
            .select("id", count="exact")\
            .eq("brand_id", brand_id)\
            .execute()

        total_products = products_response.count

        # Get total orders
        product_ids_response = self.db.table("products")\
            .select("id")\
            .eq("brand_id", brand_id)\
            .execute()

        product_ids = [p["id"] for p in product_ids_response.data]

        if product_ids:
            orders_response = self.db.table("order_items")\
                .select("order_id, quantity, unit_price_cents")\
                .in_("product_id", product_ids)\
                .execute()

            unique_orders = set(item["order_id"] for item in orders_response.data)
            total_orders = len(unique_orders)

            total_revenue = sum(
                item["quantity"] * item["unit_price_cents"]
                for item in orders_response.data
            )

            total_units_sold = sum(item["quantity"] for item in orders_response.data)
        else:
            total_orders = 0
            total_revenue = 0
            total_units_sold = 0

        return {
            "total_products": total_products,
            "total_orders": total_orders,
            "total_revenue_cents": total_revenue,
            "total_units_sold": total_units_sold,
            "average_order_value_cents": total_revenue // total_orders if total_orders > 0 else 0
        }

    async def _assign_brand_admin(self, brand_id: str, user_id: str) -> None:
        """Assign brand admin role to a user."""
        # Update user role
        self.db.table("users")\
            .update({"role": "brand"})\
            .eq("id", user_id)\
            .execute()

        # Create brand admin association
        self.db.table("brand_admins")\
            .insert({
                "brand_id": brand_id,
                "user_id": user_id
            })\
            .execute()
