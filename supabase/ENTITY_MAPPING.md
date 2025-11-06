# TypeORM ↔ Supabase Mapping

This table links the Supabase tables defined in `migrations/` to the Nest
entities under `backend/src/modules`.

| Supabase table | Migration file | TypeORM entity | Status |
| --- | --- | --- | --- |
| `carts` | `003_commerce_tables.sql` | `modules/commerce/entities/cart.entity.ts` | Needs column alignment (`free_shipping_threshold`, currency fields). |
| `cart_items` | `003_commerce_tables.sql` | `modules/commerce/entities/cart-item.entity.ts` | Ensure foreign keys and quantity constraints mirror migration. |
| `orders` | `003_commerce_tables.sql` | `modules/commerce/entities/order.entity.ts` | Add payment + referral fields. |
| `order_items` | `003_commerce_tables.sql` | `modules/commerce/entities/order-item.entity.ts` | Verify price precision and foreign keys. |
| `brands` | `004_brand_tables.sql` | `modules/brand/entities/brand.entity.ts` | Update to include analytics + onboarding flags. |
| `products` | `004_brand_tables.sql` | `modules/catalog/entities/product.entity.ts` | Align asset references and fit metadata. |
| `product_variants` | `004_brand_tables.sql` | `modules/catalog/entities/product-variant.entity.ts` | Sync size metadata + stock columns. |
| `referrals` | `005_referral_tables.sql` | `modules/referrals/entities/referral.entity.ts` | Entity missing; scaffold alongside service port. |
| `referral_events` | `005_referral_tables.sql` | _TBD_ | Create entity + repository for event tracking. |
| `referral_rewards` | `005_referral_tables.sql` | _TBD_ | Create entity + repository. |
| `refresh_tokens` | `006_auth_enhancements.sql` | `modules/auth/entities/refresh-token.entity.ts` | Validate expiry + revoked columns. |
| `failed_login_attempts` | `006_auth_enhancements.sql` | _TBD_ | Add entity for rate-limiting. |
| `brand_admins` | `007_referrals_and_brand_admins.sql` | _TBD_ | Create bridging entity to enforce multi-admin support. |

Update each entity after the migrations are wired into local development
databases. Use this checklist to track parity.
