Requirements.MD


# requirements.md 
 
> Companion to `constitutions.md`. Source of truth for UX flows, data fields, API contracts, 
validation, and acceptance criteria. 
 
## 0) Glossary 
- **AI Twin**: The user’s avatar used for try-on and fit inference. 
- **PDP**: Product Detail Page. 
- **PSP**: Payment Service Provider (tokenized cards, PCI SAQ A). 
- **RID**: Referral ID used in social links for attribution. 
 
--- 
 
## 1) Personas & Top Jobs 
 
### 1.1 Shopper (User) 
- Create account, build AI Twin, virtually try on items, receive size recommendation, purchase, 
track order, share referral link. 
 
### 1.2 Brand Admin (Client) 
- Onboard brand, upload catalog, size charts / fit mapping, 3D or parametric assets, manage 
inventory & pricing, view analytics. 
 
### 1.3 Platform Admin 
- Moderate brands, handle disputes/returns rules, manage rewards policies, audit logs. 
 
--- 
 
## 2) End-to-End Flows (Happy Path) 
 
### 2.1 Signup & Profile 
1. `Sign up` → verify email → login. 
2. Enter **height + weight** (required). Optional: photo(s), measurements, appearance fields, 
style keywords, fit prefs. 
3. Save **shipping** + **billing** addresses; add **payment method** (tokenized via PSP). 
 
**Acceptance Criteria** 
- Email verification required before checkout. 
- Password policy enforced; breached-password check passes. 
- Height/weight present; AI Twin generation kicks off asynchronously and completes within **≤ 
30s P95**. 
 
--- 
 



### 2.2 Virtual Try-On & Sizing 
1. From PDP, user clicks **“Try on”**. 
2. System renders garment on AI Twin; output includes **size recommendation** + **confidence 
(0–100)** and **fit notes by zone**. 
3. User can compare **alternate sizes**. 
 
**Acceptance Criteria** 
- Render completes ≤ **3.0s P95** after assets cached; ≤ **6.0s** on cold start. 
- Size recommendation displayed with confidence and rationale tags (e.g., *waist snug*, *sleeve 
ideal*). 
- Alternate sizes UI shows deltas (fit zones) without full rerender when possible. 
 
--- 
 
### 2.3 Checkout 
1. Add to cart → checkout on our site. 
2. Select saved **shipping**/**billing**; confirm **payment token**. 
3. Order → `paid` → `sent_to_brand` webhook. 
 
**Acceptance Criteria** 
- No raw PAN stored; PSP returns token + paymentIntentRef. 
- 3DS / AVS enforced per region. 
- Order confirmation email within 60s; status updates via email/SMS per consent. 
 
--- 
 
### 2.4 Brand Onboarding & Catalog 
1. Brand admin creates account, completes KYC (manual/backoffice), gets access to **Brand 
Portal**. 
2. Upload catalog via CSV/API; map size chart & fit rules; optionally upload 3D assets. 
3. Validate ingest; preview PDP. 
 
**Acceptance Criteria** 
- CSV schema validated; errors reported with line/field. 
- At least one size chart per garment type or parametric fallback configured. 
- Inventory visible on PDP within ≤ 5 minutes of ingest. 
 
--- 
 
### 2.5 Social Referral 
1. Shopper shares PDP with **custom URL**: 
`https://app.example.com/p/slug?rid=<RID>&utm_*` 
2. Click routes to PDP. If new user, try-on still allowed; size rec shown if AI Twin present, else 
prompt to “Estimate size from height/weight”. 



3. Purchase attributed to `RID`. Rewards queued post-return window. 
 
**Acceptance Criteria** 
- RID must be unique, non-guessable (≥128-bit). 
- Double attribution prevented (first-click priority; override rules configurable). 
- Fraud checks: device/IP/rate limits; multi-account heuristics. 
 
--- 
 
## 3) Data & Field Requirements 
 
### 3.1 User Profile (min/opt) 
- **Required**: `email`, `password`, `height`, `weight` 
- **Optional**: `name`, `phone`, `location`, `hairColor`, `eyeColor`, `skinTone` 
- **Measurements (optional)**: 
  - `waist`, `hips`, `inseam`, `chest`, `shoulderSpan`, 
  - `shoulderToChest`, `chestToNavel`, `navelToCrotch`, 
  - `thighCirc`, `armCirc`, `wristCirc`, `ankleCirc` 
- **Style**: 
  - `styleKeywords[]` (controlled vocabulary), 
  - `fitPrefs`: `{ garmentType: { zone: tight|normal|loose } }`, 
  - `torsoLengthPref`: `longer|shorter|neutral` 
- **Addresses**: 
  - `billing`: `{ line1, line2?, city, region, postalCode, country }` 
  - `shipping[]`: same schema 
- **Payments**: 
  - `paymentMethods[]`: `{ pspTokenId, brand, last4, expMonth, expYear }` (tokenized, no PAN) 
- **Avatar**: 
  - `avatarIds[]` with `version`, `meshRef`, `sources` 
 
### 3.2 Brand 
- `name`, `legal`, `supportEmail`, `domains[]`, `webhooks{order, inventory}` 
- `users[]` (RBAC: owner, admin, analyst) 
- `policies{returns, shipping, attributionWindowDays}` 
 
### 3.3 Product 
- `brandId`, `title`, `slug`, `description`, `category`, `garmentType` 
- `assets{images[], model3D?}`, `material`, `stretch`, `care` 
- `variants[]`: `{ sku, sizeLabel, color, price, currency, inventory }` 
- `sizeChartRef`, `fitMapRef` (mapping measurements → size rec rules) 
 
### 3.4 Order 
- `id`, `userId`, `items[{ productId, sku, qty, unitPrice, currency }]` 
- `shippingAddress`, `billingAddressRef`, `paymentIntentRef` 



- `status`: `created|paid|sent_to_brand|fulfilled|delivered|return_requested|closed` 
- `rid?` for referral attribution 
- `totals{subtotal, shipping, tax, grandTotal}` 
 
### 3.5 Referral 
- `rid`, `referrerUserId`, `targetProductId?`, `createdAt` 
- `clicks[]`: `{ ts, ipHash, uaHash }` 
- `attributedOrders[]: orderId` 
 
--- 
 
## 4) API (v1, REST) 
 
> Base path: `/api/v1` 
 
### 4.1 Auth 
- `POST /auth/signup` → `{ email, password }` 
- `POST /auth/login` → `{ email, password }` → `{ accessToken, refreshToken }` 
- `POST /auth/refresh` 
- `POST /auth/verify-email` → token 
- `POST /auth/mfa/enable` (optional) 
 
### 4.2 Profile 
- `GET /me` 
- `PUT /me` → update profile fields 
- `PUT /me/measurements` 
- `PUT /me/style` 
- `POST /me/avatar` → upload sources; returns `avatarId` 
- `POST /me/payment-methods` → PSP setup intent; returns `pspTokenId` 
- `POST /me/addresses` (billing/shipping) 
 
### 4.3 Catalog & Try-On 
- `GET /products?brandId=&q=&category=` 
- `GET /products/{id}` 
- `POST /tryon` → `{ avatarId|quickEstimate{height,weight}, productId, sku? }` 
  - **Response**: `{ images[]{url}, sizeRec{label, confidence, notes[]}, altSizes[] }` 
 
### 4.4 Cart & Orders 
- `POST /cart/items` → `{ productId, sku, qty }` 
- `GET /cart` 
- `POST /checkout` → `{ paymentTokenId, shippingAddressId, rid? }` 
- `GET /orders/{id}` 
 
### 4.5 Brand Portal 



- `POST /brand/catalog/upload` (CSV) 
- `POST /brand/catalog/products` (API ingest) 
- `POST /brand/sizecharts` 
- `POST /brand/fitmaps` 
- `POST /brand/assets/3d` 
- `GET /brand/analytics?range=` 
 
### 4.6 Referrals 
- `POST /referrals` → returns `{ rid, shareUrl }` 
- `GET /referrals/{rid}` → stats (auth required if owner) 
 
**General** 
- Auth: Bearer tokens (short-lived) + rotating refresh. 
- Rate limits: `/auth/*` & `/tryon` stricter. 
- Idempotency keys for `POST /checkout`. 
 
--- 
 
## 5) CSV Schemas (Brand Ingest) 
 
### 5.1 `products.csv` 
 
 
--- 
 
## 6) Validation & Business Rules 
 
- **Height**: 120–230 cm (or 4'0"–7'6"), **Weight**: 30–250 kg (or regional config). 
- **Measurements**: units stored in SI; UI accepts in/imperial → normalized server-side. 
- **Address**: country-aware postal formats; AVS when paying. 
- **Size Recommendation**: 
  - Must return one **primary** size label. 
  - Include `confidence` and at least one **note** if confidence < 70. 
- **Referral**: 
  - RID validity TTL configurable (default 30 days). 
  - One order → one RID attribution. 
  - Self-purchase allowed or blocked by policy toggle. 
 
--- 
 
## 7) Security, Privacy, Compliance 
 
- **Passwords**: Argon2id; min length & complexity; breached-password blocklist. 
- **Tokens**: Short-lived JWT + rotating refresh; device binding where possible. 



- **PII**: Encrypted at rest; field-level encryption for phones, addresses. 
- **Payments**: PSP tokens only; no PAN; PCI SAQ A. 
- **Media**: Private object storage; signed URLs; AV scanning on upload. 
- **RBAC**: Brand vs Platform vs User scopes; least privilege. 
- **Audit**: All admin/brand changes logged immutably. 
- **Privacy**: DSR endpoints for export/delete; avatar regeneration & deletion. 
 
--- 
 
## 8) Observability & SLAs 
 
- **Metrics**: try-on latency, size-rec confidence distribution, checkout conversion, referral 
attribution rate, return rate. 
- **Logs**: structured; PII-safe. Correlate `requestId`. 
- **Tracing**: try-on pipeline spans (ingest → fit → render). 
- **Targets**: 
  - Try-on P95: ≤ 3.0s (warm), ≤ 6.0s (cold). 
  - PDP TTI: ≤ 2.5s on 4G reference device. 
  - Checkout success rate: ≥ 98% (non-insufficient-funds). 
 
--- 
 
## 9) Test Plan (Key Cases) 
 
- **Auth**: signup, verify, login, refresh, rate-limit. 
- **Profile**: height/weight required; unit conversion round-trip; invalid measurement rejects. 
- **Avatar**: upload photo fallback vs. measurements only; deletion removes renders. 
- **Try-On**: with full avatar; with quickEstimate; size rec differs across two adjacent sizes; low 
confidence (<50%) messaging. 
- **Checkout**: AVS pass/fail; 3DS challenge; idempotency (double click). 
- **Brand CSV**: missing required, wrong category, duplicate SKU, invalid image URL. 
- **Referral**: RID attribution, TTL expiry, self-purchase toggle, fraud rate-limit. 
 
--- 
 
## 10) Roadmap (MVP → Next) 
 
**MVP** 
- Email/password auth, height/weight avatar, try-on renders with size rec, basic PDP, 
cart/checkout, brand CSV ingest, referral links with rewards ledger (no payouts UI), analytics v0. 
 
**Next** 
- OAuth + MFA; advanced measurements capture; 3D garment ingest; brand webhooks; 
region-aware taxes; payouts UI; returns portal; stylist GPT for outfit sets. 



 
--- 
 
## 11) Non-Goals (for MVP) 
- Marketplace for third-party apps. 
- On-site live video try-on. 
- Full influencer payout automation (manual ledger export only). 
 
--- 
 
## 12) Change Control 
- Changes to this file require approval by **Founder + Architect** and a PR referencing issue ID. 
- All revisions logged in `/changelog.md`. 
