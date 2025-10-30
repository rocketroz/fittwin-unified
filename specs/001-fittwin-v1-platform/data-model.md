# Data Model: FitTwin v1 Platform

## Overview
FitTwin persists transactional commerce data, avatar assets, and referral tracking in PostgreSQL 15 with field-level encryption for sensitive attributes. Object storage (S3-compatible) holds media artifacts referenced by metadata columns. Every entity logs auditable timestamps and supports soft delete where required to satisfy data-rights workflows.

### Core Relationships
- **UserProfile** ⟶ (1-to-N) **Avatar**, **PaymentMethod**, **Address**, **Referral**, **Order**
- **Brand** ⟶ (1-to-N) **BrandUser**, **Product**, **SizeChart**, **FitMap**
- **Product** ⟶ (1-to-N) **ProductVariant**, shares **SizeChart**/**FitMap**
- **Order** ⟶ (1-to-N) **OrderItem**, references **Referral** (optional) and stored PSP references
- **Referral** ⟶ (1-to-N) **ReferralEvent** (click, conversion, fraud flags)
- **EventLog** captures privileged actions against any entity with type metadata

## Entities

### UserProfile (`user_profiles`)
- `id` UUID PK
- `email` CITEXT UNIQUE (encrypted transport, stored normalized)
- `password_hash` TEXT (Argon2id output)
- `email_verified_at` TIMESTAMP NULL
- `username` VARCHAR(32) UNIQUE
- `name` TEXT ENCRYPTED NULL
- `phone` TEXT ENCRYPTED NULL + verification status
- `location` JSONB NULL (country, region)
- `appearance` JSONB NULL (`hairColor`, `eyeColor`, `skinTone`)
- `style_preferences` JSONB NULL (`keywords`, `fitPrefs`, `torsoLengthPref`)
- `body_metrics` JSONB (required `height_cm`, `weight_kg`, optional measurements normalized to SI)
- `default_payment_method_id` UUID FK → `payment_methods.id`
- `billing_address_id` UUID FK → `addresses.id`
- `consents` JSONB (terms, marketing, comms)
- `created_at`, `updated_at` TIMESTAMP WITH TZ

**Indexes**: `idx_user_profiles_email_lower`, `idx_user_profiles_username`, `idx_user_profiles_default_pm`.  
**Notes**: Soft delete not supported—DSR delete anonymizes PII + cascades to avatars/orders per retention policy.

### Avatar (`avatars`)
- `id` UUID PK
- `user_id` UUID FK → `user_profiles.id`
- `version` INTEGER (monotonic)
- `sources` JSONB (measurements, photo metadata, quick-estimate flag)
- `mesh_ref` TEXT NULL (signed URL / storage key)
- `status` ENUM(`processing`,`ready`,`failed`)
- `generated_at` TIMESTAMP NULL
- `confidence` SMALLINT NULL (0–100)
- `deleted_at` TIMESTAMP NULL (GDPR/DSR)

**Indexes**: `idx_avatars_user_id_status`, `idx_avatars_user_version_unique` (unique on `user_id`,`version`).

### Brand (`brands`)
- `id` UUID PK
- `name` TEXT UNIQUE
- `onboarding_status` ENUM(`invited`,`kyc_pending`,`active`,`suspended`)
- `primary_contact` JSONB (email, phone, address)
- `webhooks` JSONB NULL (event subscriptions + secrets)
- `created_at`, `updated_at`

### BrandUser (`brand_users`)
- `id` UUID PK
- `brand_id` UUID FK → `brands.id`
- `email` CITEXT UNIQUE (per brand)
- `role` ENUM(`owner`,`manager`,`analyst`)
- `status` ENUM(`invited`,`active`,`revoked`)
- `invite_token` UUID NULL (for pending accounts)
- `created_at`, `updated_at`

**Indexes**: `idx_brand_users_brand_role`, `idx_brand_users_email_unique` (partial on active status).

### Product (`products`)
- `id` UUID PK
- `brand_id` UUID FK → `brands.id`
- `title` TEXT
- `description` TEXT
- `category` TEXT (controlled taxonomy)
- `assets` JSONB (images[], models[], videourls[])
- `size_chart_id` UUID FK → `size_charts.id`
- `fit_map_id` UUID FK → `fit_maps.id`
- `status` ENUM(`draft`,`active`,`archived`)
- `created_at`, `updated_at`

### ProductVariant (`product_variants`)
- `id` UUID PK
- `product_id` UUID FK → `products.id`
- `sku` TEXT UNIQUE
- `size_label` TEXT
- `color` TEXT NULL
- `price_cents` BIGINT + `currency` CHAR(3)
- `inventory` INTEGER
- `fit_metadata` JSONB NULL (fit adjustments)
- `status` ENUM(`active`,`backorder`,`out_of_stock`)
- `created_at`, `updated_at`

**Indexes**: `idx_product_variants_product_status`, `idx_product_variants_inventory` (for low-stock alerts).

### SizeChart (`size_charts`)
- `id` UUID PK
- `brand_id` UUID FK → `brands.id`
- `garment_type` TEXT
- `measurement_rules` JSONB (body zone map → tolerance)
- `grading_rules` JSONB NULL
- `unit_system` ENUM(`metric`,`imperial`) (stored normalized)  
- `created_at`, `updated_at`

### FitMap (`fit_maps`)
- `id` UUID PK
- `brand_id` UUID FK → `brands.id`
- `garment_type` TEXT
- `rule_set` JSONB (parametric adjustments or ML model reference)
- `confidence_model` JSONB NULL (calibration coefficients)
- `created_at`, `updated_at`

### Order (`orders`)
- `id` UUID PK
- `user_id` UUID FK → `user_profiles.id`
- `status` ENUM(`created`,`paid`,`sent_to_brand`,`fulfilled`,`delivered`,`return_requested`,`closed`)
- `totals` JSONB (subtotal, tax, shipping, discounts, currency)
- `shipping_address_id` UUID FK → `addresses.id`
- `billing_address_id` UUID FK → `addresses.id`
- `payment_intent_ref` TEXT (Stripe PaymentIntent)
- `psp_token_id` TEXT (Stripe PaymentMethod)
- `rid` TEXT NULL FK → `referrals.rid`
- `notifications` JSONB NULL (email/SMS log)
- `created_at`, `updated_at`

**Indexes**: `idx_orders_user_status`, `idx_orders_rid`, `idx_orders_payment_intent`.  
**Notes**: Soft delete disabled; purge executed via retention jobs after state `closed` + policy TTL.

### OrderItem (`order_items`)
- `id` UUID PK
- `order_id` UUID FK → `orders.id`
- `product_id` UUID FK → `products.id`
- `variant_id` UUID FK → `product_variants.id`
- `sku` TEXT
- `size_label` TEXT
- `qty` SMALLINT
- `unit_price_cents` BIGINT
- `currency` CHAR(3)
- `fit_summary` JSONB NULL (sizeRec snapshot)

**Indexes**: `idx_order_items_order`, `idx_order_items_variant`.

### Address (`addresses`)
- `id` UUID PK
- `user_id` UUID FK → `user_profiles.id` NULLABLE (brand addresses)
- `type` ENUM(`billing`,`shipping`)
- `line1`, `line2`, `city`, `state`, `postal_code`, `country` TEXT (encrypted)
- `metadata` JSONB NULL (AVS results, delivery notes)
- `created_at`, `updated_at`

**Indexes**: `idx_addresses_user_type`, `idx_addresses_country_postal` (for validation).  
**Notes**: Soft delete via `deleted_at`? (Optional) – track removal in audit log.

### PaymentMethod (`payment_methods`)
- `id` UUID PK
- `user_id` UUID FK → `user_profiles.id`
- `psp_token_id` TEXT (Stripe PaymentMethod ID)
- `brand` TEXT NULL (card brand)
- `last4` CHAR(4) NULL (display only)
- `expires_at` DATE NULL
- `billing_address_id` UUID FK → `addresses.id`
- `created_at`, `updated_at`

**Indexes**: `idx_payment_methods_user`, `idx_payment_methods_psp_token` UNIQUE.

### Referral (`referrals`)
- `rid` CHAR(22) PK (base64url 128-bit)
- `referrer_user_id` UUID FK → `user_profiles.id`
- `target_product_id` UUID FK → `products.id` NULL
- `share_url` TEXT
- `policy_snapshot` JSONB (reward %, hold period)
- `expires_at` TIMESTAMP NULL
- `created_at` TIMESTAMP

**Indexes**: `idx_referrals_referrer`, `idx_referrals_target`.

### ReferralEvent (`referral_events`)
- `id` UUID PK
- `rid` CHAR(22) FK → `referrals.rid`
- `event_type` ENUM(`click`,`conversion`,`fraud_flag`)
- `order_id` UUID FK → `orders.id` NULL
- `device_fingerprint` TEXT NULL (hashed)
- `ip_hash` TEXT NULL
- `metadata` JSONB (user agent, fraud score)
- `created_at` TIMESTAMP

**Indexes**: `idx_referral_events_rid_type`, `idx_referral_events_order`.

### EventLog (`event_logs`)
- `id` UUID PK
- `actor_type` ENUM(`shopper`,`brand_admin`,`platform_admin`,`system`)
- `actor_id` UUID NULL
- `action` TEXT
- `entity_type` TEXT
- `entity_id` UUID
- `metadata` JSONB (diffs, IP, device)
- `created_at` TIMESTAMP (immutable)

**Indexes**: `idx_event_logs_entity`, `idx_event_logs_actor`, `idx_event_logs_created_at`.

### RewardLedger (`reward_ledger_entries`) *(future-proofed for referrals)*
- `id` UUID PK
- `rid` CHAR(22) FK → `referrals.rid`
- `order_id` UUID FK → `orders.id`
- `amount_cents` BIGINT
- `currency` CHAR(3)
- `status` ENUM(`pending_hold`,`payable`,`paid`,`cancelled`)
- `hold_until` DATE NULL
- `created_at`, `updated_at`

**Indexes**: `idx_reward_ledger_rid_status`, `idx_reward_ledger_order`.

## Audit & Compliance Notes
- All tables include `created_at`/`updated_at`; privileged changes mirrored to `event_logs` via triggers.  
- PII columns flagged for encryption use dedicated `pgcrypto` or application-layer envelope encryption.  
- Soft delete patterns limited to avatars and addresses to respect DSR while keeping order integrity.  
- Referential integrity uses `ON UPDATE CASCADE`, `ON DELETE RESTRICT` except for cascade deletions backed by retention policies (e.g., avatar regeneration removes prior mesh).

## Data Residency & Partitioning
- Partition `orders` and `event_logs` by month for retention + query efficiency.  
- Support regional shards by tagging `user_profiles.region` and aligning storage buckets per region for avatars/renders.  
- Implement background jobs to purge/obfuscate data after retention requirements lapse (returns, rewards, privacy deletes).
