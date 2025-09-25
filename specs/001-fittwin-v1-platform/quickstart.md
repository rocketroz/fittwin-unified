# Quickstart Scenarios: FitTwin v1 Platform

This quickstart outlines end-to-end flows to exercise the FitTwin v1 stack in staging. Each scenario lists preparation, execution steps, expected results, telemetry, and cleanup.

## Local Stack Bootstrap

1. Copy the sample environment file and adjust ports if required:
   ```bash
   cp stack.env.example stack.env
   export $(grep -v '^#' stack.env | xargs)
   ```
2. Start the full stack (Nest backend + both Next.js apps) from the repo root:
   ```bash
   npm run dev:stack
   ```
   The script wires `BACKEND_BASE_URL`, proxies API calls via `/api/backend`, and keeps processes aligned. Press `Ctrl+C` to stop all services together.
3. Run smoke tests once the stack is healthy:
   ```bash
   # run after installing browsers with `npx playwright install`
   PLAYWRIGHT_BROWSERS_READY=true npm run test:e2e
   ```
   Provide `E2E_SHOPPER_URL` / `E2E_BRAND_URL` environment variables if you customise ports.

---

## Scenario 1: Shopper Signup → Try-On → Checkout
**Goal**: Validate the happy-path shopper experience including avatar generation, size recommendation, and secure checkout.

1. **Prepare**
   - Ensure test email inbox accessible.
   - Seed catalog with at least one product having 3D assets and inventory.
2. **Signup + Verification**
   - `POST /auth/signup` with unique email + strong password.
   - Retrieve verification email in inbox; call `POST /auth/verify` with token.
   - Confirm `emailVerifiedAt` populated (`GET /me`).
3. **Profile Completion**
   - `PUT /me/body` with height 172 cm, weight 68 kg.
   - Optional: `PUT /me/profile` with appearance + style keywords.
4. **Avatar Generation**
   - `POST /me/avatar` with signed photo URLs + measurements.
   - Poll `GET /me/avatar/{id}` until `status=ready` (≤30s P95).
5. **Virtual Try-On**
   - `POST /tryon` with product + avatarId.
   - Expect `sizeRec.label` present, `confidence` > 0, `altSizes` array, response time ≤3s warm.
6. **Add to Cart**
   - `POST /cart/items` using recommended SKU.
   - `GET /cart` to confirm totals.
7. **Checkout**
   - `POST /me/payment-methods` with Stripe Setup Intent test card (e.g., 4242...).
   - `POST /checkout` with cartId, shipping & billing address IDs.
   - Expect `201` with `status=paid`, confirmation email within 60s.
8. **Post-checkout**
   - `GET /orders/{id}` returns `status=paid` then transitions to `sent_to_brand` via webhook simulation.

**Telemetry**: Verify `tryon.completed`, `checkout.success`, `orders.sent_to_brand` logs with matching requestId.  
**Cleanup**: Delete shopper via `DELETE /me` and remove test avatar assets from storage.

## Scenario 2: Avatar Regeneration & Data Rights
**Goal**: Ensure shoppers can regenerate and delete avatars, respecting data privacy.

1. Create shopper (reuse from Scenario 1) and generate avatar.
2. `POST /me/avatar` again with updated photos → should return `202`, new version increments.
3. `DELETE /me/avatar/{oldId}` — expect `204`, renders removed (signed URLs invalidated).
4. Request data export via `POST /me/export` and confirm email queued.
5. `DELETE /me` to initiate DSR; ensure user no longer able to login and data flagged for purge.

**Telemetry**: `event_logs` entries for avatar deletion and DSR request.  
**Cleanup**: Confirm background jobs purged avatars from storage.

## Scenario 3: Brand Onboarding & Catalog Ingest
**Goal**: Validate brand admin workflows, catalog ingestion, and analytics readiness.

1. Platform admin invites brand (`brands` table seeded `onboarding_status=invited`).
2. Brand owner completes KYC offline; set `onboarding_status=active`.
3. `POST /brand/sizecharts` & `/brand/fitmaps` for garment types.
4. Upload CSV via `POST /brand/catalog/upload` using signed URL.
5. Poll `GET /brand/catalog/upload/{ingestId}` until `status=completed`, zero errors.
6. `GET /products` (shopper scope) to verify new products visible within ≤5 min.
7. Trigger analytics: run sample orders, then `GET /brand/analytics?range=...` to confirm data populates.

**Telemetry**: ingestion logs (`catalog.ingest_completed`), event log entry for who activated catalog.  
**Cleanup**: Archive test brand or reset inventory.

## Scenario 4: Referral Attribution & Rewards Hold
**Goal**: Prove RID generation, attribution at checkout, and rewards hold logic.

1. Shopper A completes profile + payment method.
2. `POST /referrals` for product P → capture `rid`.
3. Shopper B (new account) visits `shareUrl` (simulate by calling PDP with `rid` param).
4. Shopper B uses quick estimate try-on (no avatar) and completes checkout via Scenario 1 steps.
5. During checkout, system calls `POST /referrals/validate`; expect `valid=true`.
6. After order `delivered`, mark return window expired (simulate job) → reward ledger entry transitions to `payable`.
7. `GET /referrals/{rid}` shows updated conversion stats and rewards counts.

**Telemetry**: `referral.click`, `referral.conversion`, `referral.reward_payable` webhook.  
**Cleanup**: Cancel rewards entry and remove test RIDs.

## Scenario 5: Failure Handling & Observability Smoke
**Goal**: Confirm error surfaces and logging across critical services.

1. Try-on asset missing: remove product asset, call `POST /tryon` → expect `409`/`ASSET_MISSING`, check logs.
2. PSP decline: run `POST /checkout` with Stripe decline card (4000 0000 0000 9995) → expect `402`, verify decline reason stored.
3. Referral self-purchase blocked: use same shopper for RID and checkout, ensure `POST /referrals/validate` returns `valid=false` with `reason="self_purchase_blocked"`.
4. Trigger rate limit by multiple `POST /auth/login` attempts; confirm `423 Locked` response and security log.

**Telemetry**: Alerts in monitoring system for try-on latency, checkout declines, security warnings.

---
Run these scenarios after each major release; failures should block promotion to production.
