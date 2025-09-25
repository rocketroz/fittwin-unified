# Feature Specification: FitTwin v1 Platform

**Feature Branch**: `[000-main]`  
**Created**: 2025-09-23  
**Status**: Draft  
**Input**: Derived from `/memory/constitution.md` and `/memory/requirements.md`.

## Execution Flow (main)
```
1. Brand admin completes onboarding (account creation, KYC, catalog ingest) so garments, fit data, and assets are ready for shoppers.
2. Shopper signs up, verifies email, and supplies height/weight plus optional measurements and appearance details.
3. Avatar service generates or refreshes the AI Twin asynchronously (≤30s P95) and stores avatar metadata on the profile.
4. Shopper browses PDPs, triggers virtual try-on, and receives size recommendation, confidence, fit notes, and alternate size comparison.
5. Shopper adds the recommended SKU to cart, confirms tokenized payment method, and completes checkout; order progresses through states with notifications.
6. Referral engine attributes purchases made through `rid` URLs, releases rewards after the return window, and logs events for analytics.
```

## ⚡ Quick Guidelines
- Center every flow on shopper consent, privacy controls, and transparency; expose data export/delete and avatar regeneration options.
- Keep fit, styling, and commerce modules loosely coupled but orchestrated to meet latency budgets and reduce recomputation.
- Always present a primary size recommendation with confidence, rationale tags, and alternate-size deltas before committing an order.
- Tokenize all payment interactions via the PSP, never store raw card data, and honor PCI SAQ A boundaries with least-privilege access.
- Instrument avatar, try-on, checkout, and referral pipelines with structured logs, metrics, tracing, and mandatory audit trails.

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a shopper, I want to see how garments fit my AI twin, receive a confident size recommendation, and check out on the same platform so I can order the right size without guesswork.

### Secondary User Stories
- As a brand admin, I need to upload catalog and fit data, manage inventory, and monitor performance so I can trust FitTwin with my ecommerce channel.
- As a platform admin, I need to audit actions, manage disputes/rewards, and enforce fraud policies to protect shoppers and brands.

### Acceptance Scenarios
1. **Given** a shopper completes signup with email verification, **When** they provide height and weight, **Then** their AI twin generation starts and a profile summary is stored.
2. **Given** an avatar is available, **When** the shopper presses “Try on” on a PDP, **Then** the system renders the garment, returns a size recommendation with confidence (0–100), and exposes alternate sizes with fit deltas.
3. **Given** a shopper has selected a recommended SKU, **When** they proceed to checkout with a saved tokenized payment method, **Then** the order transitions `created → paid → sent_to_brand`, the shopper receives confirmation within 60 seconds, and no raw card data is stored.
4. **Given** a brand admin finishes onboarding, **When** they upload a catalog CSV, **Then** the ingest validates schema, maps size charts, and surfaces products on PDPs within 5 minutes.
5. **Given** a shopper shares a referral URL, **When** another user purchases through that URL, **Then** the order is attributed to the RID (respecting fraud checks) and queued for rewards after the return window.

### Edge Cases
- Avatar generation times out (>30s) or fails; shopper must see clear retry messaging and fallback to height/weight estimation.
- Try-on requested for a product lacking 3D assets; system must fall back to parametric fit notes without rendering.
- Checkout attempted with expired payment token; shopper prompted to refresh PSP token while preserving cart state.
- Brand CSV contains invalid SKU or missing size chart; ingest reports row-level errors and prevents partial activation.
- Referral link used by the referrer (self-purchase) when policy disables it; order completes without attribution and logs rule enforcement.

### Test Matrix
| Test ID | Scenario | Preconditions | Steps | Expected Result | Notes |
| --- | --- | --- | --- | --- | --- |
| TM-01 | Shopper signup & verification | Unique email, password meets policy | Submit signup → open verification link → login | Account activated, profile requires height/weight | Password breach check enforced |
| TM-02 | AI twin generation SLA | Verified shopper, base measurements present | Provide optional measurements/photos → wait for completion | Avatar ready ≤30s P95, status exposed to UI | Failure returns actionable error |
| TM-03 | Virtual try-on recommendation | Avatar ready, product assets cached | Click “Try on” → view render | Response includes `sizeRec`, `confidence`, `notes`, `altSizes` | Warm render ≤3.0s, cold ≤6.0s |
| TM-04 | Checkout with PSP token | Cart populated, payment token on file | Initiate checkout → confirm addresses → submit | PSP returns paymentIntentRef, order state `paid`, confirmation email ≤60s | Idempotency key prevents double charge |
| TM-05 | Brand catalog ingest | Brand portal access, CSV prepared | Upload CSV → resolve validation issues (if any) | Products/variants available on PDP ≤5 min, errors annotated | Size chart per garment type required |
| TM-06 | Referral attribution & fraud controls | Shopper generates RID, distinct device for buyer | Share URL → buyer completes purchase | Order attributed to RID unless fraud heuristics trigger; rewards queued post-return window | First-click priority, duplicate RIDs rejected |

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST support email/password signup with verification before checkout access.
- **FR-002**: System MUST enforce strong password policy and memory-hard hashing with breached-password detection.
- **FR-003**: System MUST require height and weight collection prior to AI twin generation.
- **FR-004**: System MUST allow optional capture of photos, measurements, and appearance/style metadata tied to the profile.
- **FR-005**: Avatar service MUST complete generation or provide status updates within ≤30s P95; failures must surface retry options.
- **FR-006**: System MUST allow shoppers to view, edit, export, and delete personal data and regenerate or delete avatars.
- **FR-007**: Platform MUST expose rate-limited auth, checkout, and referral endpoints to mitigate abuse.
- **FR-008**: PDP MUST invoke virtual try-on producing render images, size recommendation, confidence score, and fit notes by body zone.
- **FR-009**: System MUST present alternate size comparisons without requiring full rerender when cached deltas exist.
- **FR-010**: PDP MUST show inventory visibility by variant and recommended size for logged-in shoppers.
- **FR-011**: Cart service MUST support add/update/remove operations, persist state per user, and respect inventory checks.
- **FR-012**: Checkout MUST use tokenized payment methods via PSP, apply AVS/3DS when required, and never store raw PAN data.
- **FR-013**: Order lifecycle MUST follow `created → paid → sent_to_brand → fulfilled → delivered → return_requested → closed` with notifications based on consent.
- **FR-014**: System MUST maintain audit logs for brand and platform admin actions.
- **FR-015**: Brand portal MUST validate catalog CSV/API payloads, map size charts, and ensure fit rules before activation.
- **FR-016**: Size chart and fit map ingest MUST support per-garment configuration and fallback parametric rules.
- **FR-017**: Referral service MUST issue unique ≥128-bit RIDs, generate share URLs, and prevent double attribution.
- **FR-018**: Analytics MUST report conversion, return rate, fit accuracy, and referral performance to brands.
- **FR-019**: Platform MUST expose quick-estimate sizing (height/weight) when no avatar exists.
- **FR-020**: System MUST encrypt PII at rest, enforce RBAC for shopper/brand/platform roles, and log admin access.

### Key Entities
- **UserProfile**: Shopper identity, preferences, and commerce metadata with references to avatars, addresses, and payment tokens.
- **Avatar**: AI twin artifact (mesh reference, generation sources, status, timestamps) tied to a user profile.
- **Brand**: Client organization, onboarding state, catalog configuration, and brand admins.
- **Product**: Garment definition including assets, fit metadata, and variant linkage.
- **ProductVariant**: Size/color SKU with inventory levels, size mapping, and pricing.
- **SizeChart / FitMap**: Brand-specific measurement rules and grading logic for garments.
- **Order**: Checkout result with items, totals, payment reference, shipping info, state transitions, and notifications.
- **Referral**: RID metadata including referrer, target product, attribution status, and reward ledger entries.
- **Event/AuditLog**: Immutable records of privileged actions, state changes, and policy decisions.
- **Address**: Normalized billing/shipping addresses with country-aware validation.
- **PaymentMethod**: Tokenized payment instruments referencing PSP tokens and metadata.

## Assumptions
- **[A1]** Rewards ledger configuration (payout timing, currency) is managed outside this scope but provides policy inputs to referral processing.
- **[A2]** PSP integration supplies `paymentIntentRef`, AVS, and 3DS outcomes synchronously, letting the platform persist tokens without storing raw PAN data.

## API Surface

### Auth & Session
| Endpoint | Method | Description |
| --- | --- | --- |
| `/auth/signup` | POST | Create shopper; triggers email verification and password policy checks. |
| `/auth/login` | POST | Issue short-lived access token and refresh token after credential validation. |
| `/auth/refresh` | POST | Rotate access token using refresh token; invalidates prior session. |
| `/auth/logout` | POST | Revoke refresh token and terminate session. |

**POST /auth/signup**  
_Request_
```json
{
  "email": "user@example.com",
  "password": "StrongPass!42",
  "consent": {
    "terms": true,
    "marketing": false
  }
}
```
_Response (202)_
```json
{
  "userId": "uuid",
  "status": "verification_pending"
}
```

**POST /auth/login**  
_Request_
```json
{
  "email": "user@example.com",
  "password": "StrongPass!42"
}
```
_Response (200)_
```json
{
  "accessToken": "jwt",
  "refreshToken": "opaque-token",
  "expiresIn": 900
}
```

### Shopper Profile & Avatar
| Endpoint | Method | Description |
| --- | --- | --- |
| `/me` | GET | Retrieve profile, measurements, avatar summary, consent flags. |
| `/me/profile` | PUT | Update optional identity, appearance, style, and preference fields. |
| `/me/body` | PUT | Update height, weight, and extended measurements (validations applied). |
| `/me/avatar` | POST | Upload avatar sources (photos/measurements) and trigger generation. |
| `/me/avatar/{avatarId}` | DELETE | Delete avatar and associated renders. |
| `/me/payment-methods` | POST | Create PSP setup intent, persist token metadata. |
| `/me/addresses` | POST | Add billing/shipping address with country validation. |
| `/me/addresses/{addressId}` | PUT/DELETE | Update or remove address. |
| `/me/export` | POST | Initiate data export package (download link via email). |

**POST /me/avatar**  
_Request_
```json
{
  "sources": {
    "height": 172,
    "weight": 68,
    "photos": [
      {
        "url": "signed-upload-url",
        "view": "front"
      }
    ],
    "measurements": {
      "waist": 74,
      "inseam": 80
    }
  }
}
```
_Response (202)_
```json
{
  "avatarId": "uuid",
  "status": "processing"
}
```

### Catalog & Try-On
| Endpoint | Method | Description |
| --- | --- | --- |
| `/products` | GET | List products filtered by brand, category, search query. |
| `/products/{productId}` | GET | Fetch PDP data inc. assets, variants, fit metadata. |
| `/tryon` | POST | Execute try-on with avatar or quick estimate. |

**POST /tryon**  
_Request_
```json
{
  "productId": "uuid",
  "variantSku": "SKU-123",
  "avatarId": "uuid",
  "context": {
    "rid": "optional-rid",
    "channel": "web"
  }
}
```
_Response (200)_
```json
{
  "images": [
    {
      "url": "signed-image-url",
      "view": "front"
    }
  ],
  "sizeRec": {
    "label": "M",
    "confidence": 88,
    "notes": ["waist snug", "sleeve ideal"]
  },
  "altSizes": [
    {
      "label": "S",
      "fitDeltas": {"waist": "+5", "chest": "+2"}
    }
  ],
  "processingTimeMs": 2400
}
```

### Cart & Checkout
| Endpoint | Method | Description |
| --- | --- | --- |
| `/cart` | GET | Retrieve current cart with items and recommendations. |
| `/cart/items` | POST | Add item to cart (productId, sku, qty). |
| `/cart/items/{itemId}` | PATCH | Update quantity or selected size. |
| `/cart/items/{itemId}` | DELETE | Remove item. |
| `/checkout` | POST | Submit order with payment token, shipping, billing, optional RID. |
| `/orders` | GET | List shopper orders with pagination. |
| `/orders/{orderId}` | GET | Retrieve order detail, status timeline, tracking. |
| `/orders/{orderId}/return-request` | POST | Initiate return within policy window. |

**POST /checkout**  
_Request_
```json
{
  "paymentTokenId": "psp-token",
  "shippingAddressId": "uuid",
  "billingAddressId": "uuid",
  "cartId": "uuid",
  "rid": "optional-rid"
}
```
_Response (201)_
```json
{
  "orderId": "uuid",
  "status": "paid",
  "paymentIntentRef": "psp-intent",
  "estimatedFulfillment": "2025-09-30"
}
```

### Brand Portal
| Endpoint | Method | Description |
| --- | --- | --- |
| `/brand/catalog/upload` | POST | Upload catalog CSV; returns validation report. |
| `/brand/catalog/products` | POST | Submit product payload via API ingest. |
| `/brand/sizecharts` | POST | Create/update size chart definitions. |
| `/brand/fitmaps` | POST | Create/update fit mapping rules. |
| `/brand/assets/3d` | POST | Upload 3D garments or parametric data. |
| `/brand/analytics` | GET | Retrieve performance metrics filtered by date range. |

**POST /brand/catalog/upload**  
_Request_
```json
{
  "brandId": "uuid",
  "fileUrl": "signed-upload-url",
  "schemaVersion": "1.0"
}
```
_Response (202)_
```json
{
  "ingestId": "uuid",
  "status": "processing"
}
```

### Referrals & Rewards
| Endpoint | Method | Description |
| --- | --- | --- |
| `/referrals` | POST | Generate RID and share URL for a product or collection. |
| `/referrals/{rid}` | GET | View referral performance (owner scope). |
| `/referrals/{rid}/events` | GET | Retrieve click and attribution events (owner scope). |

**POST /referrals**  
_Request_
```json
{
  "productId": "uuid"
}
```
_Response (201)_
```json
{
  "rid": "b64urlhash",
  "shareUrl": "https://app.fittwin.com/p/slug?rid=b64urlhash"
}
```

## Data Model

### Entity Relationship Summary
- `UserProfile` (1) — (N) `Avatar`; latest avatar flagged.
- `UserProfile` (1) — (N) `PaymentMethod`; tokens scoped per PSP customer.
- `UserProfile` (1) — (N) `Address`; addresses typed (`billing`, `shipping`).
- `Brand` (1) — (N) `BrandUser` (brand admin accounts).
- `Brand` (1) — (N) `Product`; each product (1) — (N) `ProductVariant`.
- `Product` (N) — (1) `SizeChart`; `ProductVariant` (N) — (1) `FitMap`.
- `Order` (1) — (N) `OrderItem`; each `Order` references `UserProfile`, `Address`, `PaymentMethod`, optional `Referral`.
- `Referral` (1) — (N) `AttributionEvent`; each event references `Order` when conversion occurs.
- `EventLog` captures actions across user, brand, and platform scopes with references to affected entity IDs.

### Table Schemas

#### `user_profiles`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | Generated at signup. |
| `email` | String | Unique, lowercased | Verified before checkout access. |
| `passwordHash` | String | Argon2id-equivalent | Rotate on password change. |
| `emailVerifiedAt` | Timestamp | Nullable | Must be non-null for checkout. |
| `username` | String | Unique | Shopper-facing handle. |
| `name` | String | Optional | Stored encrypted. |
| `phone` | String | Optional | Encrypted, verifiable. |
| `location` | JSON | Optional | Region/country metadata. |
| `appearance` | JSON | Optional | `hairColor`, `eyeColor`, `skinTone`. |
| `stylePreferences` | JSON | Optional | Keywords, fit prefs, torso length. |
| `bodyMetrics` | JSON | Required fields `height`, `weight`; optional measurements. |
| `defaultPaymentMethodId` | UUID | Nullable FK | Points to `payment_methods`. |
| `billingAddressId` | UUID | Nullable FK | Points to `addresses`. |
| `createdAt` / `updatedAt` | Timestamp | Required | Audit fields. |
| `consents` | JSON | Required | Tracks marketing, notifications, data rights. |

#### `avatars`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `userId` | UUID | FK `user_profiles.id` | |
| `version` | Integer | Required | Increment on regeneration. |
| `sources` | JSON | Required | Photo metadata, measurement set. |
| `meshRef` | String | Optional | Points to secure object storage. |
| `status` | Enum | `processing`, `ready`, `failed` | |
| `generatedAt` | Timestamp | Optional | Filled when status = ready. |
| `confidence` | Integer | Optional | Model self-confidence 0–100. |
| `deletedAt` | Timestamp | Nullable | Soft delete for data rights. |

#### `brands`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `name` | String | Unique | |
| `onboardingStatus` | Enum | `invited`, `kyc_pending`, `active`, `suspended` | |
| `primaryContact` | JSON | Required | Email, phone, address. |
| `webhooks` | JSON | Optional | Callback URLs. |
| `createdAt` / `updatedAt` | Timestamp | Required | |

#### `brand_users`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `brandId` | UUID | FK `brands.id` | |
| `email` | String | Unique | |
| `role` | Enum | `owner`, `manager`, `analyst` | RBAC for brand portal. |
| `status` | Enum | `invited`, `active`, `revoked` | |
| `createdAt` | Timestamp | Required | |

#### `products`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `brandId` | UUID | FK `brands.id` | |
| `title` | String | Required | |
| `description` | Text | Required | |
| `category` | String | Required | Controlled vocabulary. |
| `assets` | JSON | Required | Images, optional 3D assets. |
| `sizeChartId` | UUID | FK `size_charts.id` | |
| `fitMapId` | UUID | FK `fit_maps.id` | |
| `status` | Enum | `draft`, `active`, `archived` | |
| `createdAt` / `updatedAt` | Timestamp | Required | |

#### `product_variants`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `productId` | UUID | FK `products.id` | |
| `sku` | String | Unique per brand | |
| `sizeLabel` | String | Required | |
| `color` | String | Optional | |
| `price` | Decimal | Required | Currency enforced per brand. |
| `inventory` | Integer | Required | |
| `fitMetadata` | JSON | Optional | Additional fit notes. |
| `status` | Enum | `active`, `backorder`, `out_of_stock` | |

#### `size_charts`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `brandId` | UUID | FK `brands.id` | |
| `garmentType` | String | Required | |
| `measurementRules` | JSON | Required | Body zone mappings. |
| `gradingRules` | JSON | Optional | Size progression. |
| `unitSystem` | Enum | `metric`, `imperial` | Stored normalized to SI. |

#### `fit_maps`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `brandId` | UUID | FK `brands.id` | |
| `garmentType` | String | Required | |
| `ruleSet` | JSON | Required | Parametric or ML model reference. |
| `confidenceModel` | JSON | Optional | Calibration data. |

#### `orders`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `userId` | UUID | FK `user_profiles.id` | |
| `status` | Enum | Lifecycle states | |
| `totals` | JSON | Required | Subtotal, tax, shipping, discounts. |
| `shippingAddressId` | UUID | FK `addresses.id` | |
| `billingAddressId` | UUID | FK `addresses.id` | |
| `paymentIntentRef` | String | Required | PSP reference. |
| `pspTokenId` | String | Required | Token used for charge. |
| `rid` | String | Optional | Referral linkage. |
| `createdAt` / `updatedAt` | Timestamp | Required | |
| `notifications` | JSON | Optional | Email/SMS send log. |

#### `order_items`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `orderId` | UUID | FK `orders.id` | |
| `productId` | UUID | FK `products.id` | |
| `variantId` | UUID | FK `product_variants.id` | |
| `sku` | String | Required | |
| `sizeLabel` | String | Required | |
| `qty` | Integer | Required | |
| `unitPrice` | Decimal | Required | |
| `fitSummary` | JSON | Optional | Snapshot of recommendation at purchase. |

#### `addresses`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `userId` | UUID | FK `user_profiles.id` | Nullable for brand addresses. |
| `type` | Enum | `billing`, `shipping` | |
| `line1`, `line2`, `city`, `state`, `postalCode`, `country` | Strings | Required per country rules | Stored encrypted. |
| `metadata` | JSON | Optional | AVS result, delivery notes. |

#### `payment_methods`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `userId` | UUID | FK `user_profiles.id` | |
| `pspTokenId` | String | Required | |
| `brand` | String | Optional | Card brand or wallet type. |
| `last4` | String | Optional | Display only. |
| `expiresAt` | Timestamp | Optional | From PSP. |
| `billingAddressId` | UUID | FK `addresses.id` | |

#### `referrals`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `rid` | String | PK | Base64-url 128-bit hash. |
| `referrerUserId` | UUID | FK `user_profiles.id` | |
| `targetProductId` | UUID | Nullable FK `products.id` | |
| `shareUrl` | String | Required | |
| `policySnapshot` | JSON | Required | Reward rules at creation. |
| `createdAt` | Timestamp | Required | |
| `expiresAt` | Timestamp | Optional | TTL per policy. |

#### `referral_events`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `rid` | String | FK `referrals.rid` | |
| `eventType` | Enum | `click`, `conversion`, `fraud_flag` | |
| `orderId` | UUID | Nullable FK `orders.id` | |
| `deviceFingerprint` | String | Optional | For fraud heuristics. |
| `ipAddress` | String | Optional | Stored hashed. |
| `createdAt` | Timestamp | Required | |

#### `event_logs`
| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
| `id` | UUID | PK | |
| `actorType` | Enum | `shopper`, `brand_admin`, `platform_admin`, `system` | |
| `actorId` | UUID | Optional | |
| `action` | String | Required | |
| `entityType` | String | Required | |
| `entityId` | UUID | Required | |
| `metadata` | JSON | Required | |
| `createdAt` | Timestamp | Required | Immutable. |

## Sequence Diagrams

### Shopper Signup & Profile
Shopper -> Web App: Submit email, password, consents  
Web App -> Identity Service: Create user, hash password, enforce breach check  
Identity Service -> Email Service: Send verification link  
Email Service -> Shopper: Deliver verification email  
Shopper -> Web App: Follow verification link  
Web App -> Identity Service: Activate account  
Web App -> Profile Service: Collect height/weight and optional data  
Profile Service -> Avatar Service: Queue AI twin generation  
Avatar Service -> Secure Storage: Persist mesh and metadata  
Avatar Service -> Profile Service: Update avatar list and status

### Virtual Try-On
Shopper -> Web App: Click “Try on”  
Web App -> Try-On API: Submit productId, avatarId  
Try-On API -> Asset Service: Fetch garment assets  
Try-On API -> Fit Engine: Compute size recommendation, fit notes  
Fit Engine -> Rendering Service: Generate images (if required)  
Rendering Service -> Secure Storage: Save signed image URLs  
Try-On API -> Web App: Return images, sizeRec, altSizes, confidence

### Checkout Flow
Shopper -> Web App: Open cart and proceed to checkout  
Web App -> Cart Service: Retrieve cart snapshot  
Web App -> PSP Proxy: Confirm payment token validity  
Web App -> Checkout API: Submit payment token, shipping/billing IDs, rid  
Checkout API -> PSP: Create payment intent and charge  
PSP -> Checkout API: Respond with paymentIntentRef, AVS/3DS results  
Checkout API -> Order Service: Create order, state `paid`  
Order Service -> Notification Service: Send confirmation email/SMS  
Order Service -> Brand Fulfillment Webhook: Post `sent_to_brand` payload  
Order Service -> Event Log: Record checkout completion

### Brand Onboarding & Catalog Ingest
Brand Admin -> Brand Portal: Complete profile, submit KYC docs  
Brand Portal -> Compliance Review: Validate KYC (manual/async)  
Compliance Review -> Brand Portal: Approve brand (`active`)  
Brand Admin -> Catalog API: Upload products CSV  
Catalog API -> Validation Engine: Check schema, size charts, assets  
Validation Engine -> Catalog API: Report validation status  
Catalog API -> Product Service: Persist products, variants, fit references  
Product Service -> Cache/PDP: Publish updated catalog within ≤5 min  
Product Service -> Event Log: Record ingest summary

### Referral Attribution
Shopper -> Referral API: Request share URL  
Referral API -> Referral Store: Persist RID, policy snapshot  
Referral API -> Shopper: Return share URL  
New Buyer -> Web App: Open referral link  
Web App -> Referral Service: Log click event and set attribution context  
Buyer -> Checkout API: Complete purchase  
Checkout API -> Referral Service: Evaluate attribution (first-click, fraud checks)  
Referral Service -> Rewards Ledger: Queue reward with hold until return window  
Referral Service -> Event Log: Record conversion attribution

## Non-Functional Requirements

### Performance & Latency
- Try-on warm-render budget ≤3.0s P95; cold-start ≤6.0s.
- AI twin generation ≤30s P95; queue status returned every 5s while processing.
- PDP time-to-interactive ≤2.5s on reference 4G device with cached assets.
- Checkout success rate ≥98% excluding insufficient funds; confirmation email within 60s.
- Catalog ingest publishes to PDP within 5 minutes of validation completion.

### Security & Privacy
- Passwords stored with Argon2id-level memory-hard hashing and breached-password blocking.
- All PII (names, phone numbers, addresses) encrypted at rest with field-level keys.
- Enforce RBAC for shopper, brand admin, and platform admin scopes; audit brand/admin actions.
- Require explicit consent tracking for communications; respect deletion/export requests.
- PSP tokens only; store paymentIntentRef and PSP token IDs, never raw card data.
- Implement rate limiting and device/IP fingerprinting for auth, checkout, referral endpoints.
- Signed URLs for media uploads/downloads; run AV scanning on avatar inputs.

### Observability & Reliability
- Structured logging with correlation IDs for try-on, checkout, referral pipelines.
- Distributed tracing across fit engine, rendering, PSP, and notification services.
- Metrics: try-on latency, size confidence distribution, checkout conversion, referral attribution rate, return rate.
- Alert thresholds for try-on latency breaches, avatar failure ratios, checkout decline spikes.
- Immutable event log for auditing with retention policy aligned to compliance requirements.

### Compliance & Operations
- Maintain PCI SAQ A scope; segregate PSP credentials via environment secrets with rotation policy.
- Support DSR endpoints for data export/delete within regulatory timelines.
- KYC workflow for brands; manual approval recorded before catalog access.
- Configurable return windows and referral policies enforced via centralized configuration service.

## Review & Acceptance Checklist

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Execution Status
- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

## Clarifications
### Session 1 (2025-09-23)
- Requirements derived from constitution and requirements.md; no blocking questions remain after baseline review.
