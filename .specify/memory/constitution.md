9-23-25 
 
 
# constitutions.md 
 
## 1) Memory (Founder Narrative) 
 
This company exists to eliminate guesswork in online apparel. We use AI to let customers 
**virtually try on** clothing with an **AI avatar twin** so they can order the **right size the first 
time**. Beyond fit, an **AI stylist** learns each person’s style and body type to suggest pieces 
they’ll actually love. 
 
Core experiences: 
- **Virtual Fitting Room**: users see garments on their AI twin before purchase. 
- **Accurate Sizing**: brand- and garment-specific fit guidance drives down returns. 
- **Personal Styling**: style keywords, fit preferences, and body geometry inform 
recommendations. 
- **Social Commerce**: users share a **custom URL** to drive purchases and earn rewards. 
 
This is a company at the intersection of **AI, fashion, and community**, built to reduce returns, 
increase brand trust, and make online shopping personal. 
 
--- 
 
## 2) Mission & Vision 
 
**Mission**   
Transform fashion e-commerce by unifying avatar-based try-on, precise sizing, and AI styling in 
a seamless purchase flow. 
 
**Vision**   
Every shopper knows what fits and looks good—before buying—and every brand sells with 
fewer returns and higher loyalty. 
 
--- 
 
## 3) Core Principles 
 
- **First-Principles Architecture**: derive from root problems (fit, returns, personalization). 
- **Evolvability**: prefer designs that can change without rewrites. 
- **User-Centered**: prioritize clarity, consent, privacy, and control. 
- **Brand Partnership First**: easy ingest of catalogs and sizing metadata. 
- **Security & Compliance by Default**: protect PII and payments rigorously. 
- **Social as a Core Loop**: referral links and rewards are core infra, not a plug-in. 



 
--- 
 
## 4) Product Constitution (Rules of the Product) 
 
### 4.1 Accounts & Profiles 
- Users create an account with **username + password** (email verified).   
  - Optional future: OAuth (Apple/Google) and **MFA**. 
- **Profile stores** (minimum set): 
  - Identity: username, email (verified), phone (optional, verifiable), name (optional), location 
(optional). 
  - Appearance: hair color, eye color, skin tone (optional). 
  - Body inputs: photo(s), height, weight (required for basic avatar). 
  - Extended measurements (optional): waist, hips, inseam, chest, shoulder span, 
shoulder→chest, chest→navel, navel→crotch, thigh/arm/wrist/ankle circumferences, etc. 
  - Style: **style keywords** (from controlled list), **fit prefs** (tight/normal/loose) by garment & 
body zone, torso length preference (longer/shorter shirts). 
  - Commerce: **default payment token** (tokenized), billing address, shipping address(es). 
- **Privacy controls**: users can view/export/delete their data and **regenerate or delete 
avatars**. 
 
### 4.2 Virtual Fitting Room 
- Inputs: user avatar + garment (with size/fit metadata + 3D/parametric garment data). 
- Output: visual render + **size recommendation with confidence** (per brand/garment). 
- UX must explicitly state **recommended size** and show an “alternate sizes” comparison. 
 
### 4.3 Commerce & Checkout 
- **Single-stack checkout on our site** after try-on.   
- **Saved to profile**: payment method (tokenized via PSP), billing address, email, phone, 
delivery address.   
- **Never store raw card data**—use PSP tokens (PCI DSS SAQ A posture). 
- Order states: `created → paid → sent_to_brand → fulfilled → delivered → return_requested → 
closed`. 
- **Email/SMS notifications** for order updates (respecting comms consent). 
 
### 4.4 Brand (Client) Portal 
- Brand onboarding: 
  - Upload product catalog (CSV/API), including **SKU variants**, size charts, fabric attributes, 
and **fit mapping**. 
  - Upload **3D assets** or provide patterns/measure tables; platform supports fallback 
parametric fit. 
- Controls: 
  - Manage catalog, inventory, pricing, promotions, and **return rules**. 
  - View analytics: conversion, return rate, fit accuracy, and social-referral performance. 



 
### 4.5 Social Commerce 
- Each shared product/post generates a **custom URL** with a unique identifier (e.g., 
`?rid=<hash>`).   
- Clicks on the URL route to the **product page on our site** with a preselected size 
recommendation (if user is logged in / avatar available).   
- Purchases attributed to the **referrer** for rewards; attribution window and anti-fraud checks 
defined in config. 
- **UTM** parameters permitted; internal **RID** is authoritative for rewards. 
 
--- 
 
## 5) Technical Constitution (Engineering Rules) 
 
### 5.1 Architecture & Derivation 
- **Architecture-first**: choose primitives that keep the fitting room + commerce independent yet 
integrated (services or well-bounded modules). 
- **Prefab vs Derive**: prefer deriving core fit/styling logic; use prefab for commodity layers 
(auth, payments, analytics) **only** if they don’t restrict evolvability. 
 
### 5.2 Data Model (initial, high-level) 
- **UserProfile** 
  - `id, username, email, phone?, name?, location?` 
  - `appearance: {hairColor?, eyeColor?, skinTone?}` 
  - `body: {height, weight, measurements?{...}}` 
  - `style: {keywords:[...], fitPrefs:{byGarment/byZone}, torsoLengthPref}` 
  - `addresses: {billing, shipping[]}` 
  - `paymentMethods: [paymentTokenId]` (tokenized by PSP) 
  - `avatarIds: [ids]` 
- **Avatar** 
  - `id, userId, version, sources(photo, scans?), meshRef, createdAt` 
- **Brand** 
  - `id, name, onboardingStatus, webhooks?, users[]` 
- **Product** 
  - `id, brandId, title, description, assets{images, model3D?}, sizeChartRef, fitMapRef, 
variants[SKU]` 
- **FitMap / SizeChart** 
  - `brandId, garmentType, measurementMappingRules, gradingRules` 
- **Order** 
  - `id, userId, items[{productId, sku, size, price}], totals, shippingAddress, status, 
paymentIntentRef` 
- **Referral** 
  - `rid, referrerUserId, targetProductId?, clicks, attributedOrders[]` 
- **Event/Audit** 



  - `who, what, when, metadata` 
 
### 5.3 Auth & Security 
- Passwords: **Argon2id** hashing, strong policy, breached-password checks.   
- Sessions: short-lived JWT + rotating refresh tokens; device-bound where possible.   
- **MFA** optional (TOTP, SMS).   
- Rate limiting + IP/device fingerprinting for auth, checkout, referrals.   
- **PII & sensitive fields encrypted at rest**; strict RBAC on Brand and Admin portals.   
- **Audit logging** for admin/brand actions. 
 
### 5.4 Payments & Compliance 
- Use a PCI-compliant **Payment Service Provider (PSP)**; we **only store tokens**.   
- PCI **SAQ A** scope, segregated environment variables, key rotation.   
- Address verification (AVS) + 3DS where available. 
 
### 5.5 Observability & Quality 
- Logging (structured), tracing, and metrics for: fit computations, try-on latency, checkout, 
referral attribution.   
- **Tests required**: 
  - Unit: avatar pipeline, size recommendation, referral attribution, orders. 
  - E2E: try-on → add-to-cart → checkout → order webhooks. 
- Performance budgets for try-on render and PDP load. 
 
--- 
 
## 6) Operating Cadence 
 
### 6.1 Branching & Commits 
- Branches: `main` (prod), `dev` (integration), `feature/<name>`.   
- Commits: 
 
 
 
Examples:   
- `feat: virtual fitting room size confidence output` 
- `fix: referral RID validation on checkout` 
- `docs: brand catalog CSV schema` 
 
### 6.2 Reviews & Releases 
- PRs link to an issue/epic; **≥1 reviewer**.   
- CI: lint, tests, typecheck, vulnerability scan.   
- CD: blue/green or canary for the web app. 
 
### 6.3 Docs & Source of Truth 



- `/docs` contains API specs, data schemas, and brand CSV/API spec.   
- `/SECURITY.md` covers reporting & handling.   
- `/PRIVACY.md` covers data rights, avatar deletion, and retention. 
 
--- 
 
## 7) Future-Proofing 
 
- **Swappable Fit Engine**: isolate fit inference from rendering; support multiple models.   
- **Asset Flexibility**: support parametric garments now; enable 3D/DXF/CLO ingest later.   
- **Extensible Style Layer**: new style taxonomies without DB migrations.   
- **Geo & Compliance**: consent banners, DSR tooling, and data residency by region.   
- **Ecosystem**: public APIs/webhooks for brands; later: partner marketplace. 
 
--- 
 
## 8) Living Document 
 
This constitution is **versioned**.   
- Changes require **founder + architect** approval.   
- Record revisions in `/changelog.md` with date, author, and rationale. 
