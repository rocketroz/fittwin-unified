# Tasks: FitTwin v1 Platform

**Input**: Design artifacts in `/specs/001-fittwin-v1-platform/`
**Prerequisites**: plan.md (completed), research.md, data-model.md, contracts/, quickstart.md

## Phase 3.1: Setup
- [X] T001 Scaffold backend NestJS workspace in `backend/` with module skeletons (auth, profiles, tryon, commerce, referrals, brand)
- [X] T002 Establish queue worker packages for avatar and try-on rendering in `backend/queue-workers/`
- [X] T003 [P] Initialize shopper & brand Next.js apps with shared UI package in `frontend/apps/`
- [X] T004 [P] Configure repo tooling (ESLint, Prettier, Jest, Playwright, Husky) in `package.json` and `.github/workflows/ci.yml`

## Phase 3.2: Tests First (TDD)
- [X] T005 [P] Author auth contract tests in `backend/tests/contract/auth/auth.contract.spec.ts`
- [X] T006 [P] Author profile/DSR contract tests in `backend/tests/contract/profile/profile.contract.spec.ts`
- [X] T007 [P] Author try-on contract tests in `backend/tests/contract/tryon/tryon.contract.spec.ts`
- [X] T008 [P] Author commerce (cart/checkout/orders) contract tests in `backend/tests/contract/commerce/commerce.contract.spec.ts`
- [X] T009 [P] Author brand portal contract tests in `backend/tests/contract/brand/brand.contract.spec.ts`
- [X] T010 [P] Author referrals/rewards contract tests in `backend/tests/contract/referrals/referrals.contract.spec.ts`
- [X] T011 [P] Implement shopper end-to-end integration flow (Scenario 1) in `backend/tests/integration/shopper_checkout.spec.ts`
- [X] T012 [P] Implement shopper Playwright e2e flow (Scenario 1 UI) in `frontend/apps/shopper/tests/e2e/shopper-flow.spec.ts`
- [X] T013 [P] Implement avatar regeneration integration test (Scenario 2) in `backend/tests/integration/avatar_regeneration.spec.ts`
- [X] T014 [P] Implement brand catalog ingest integration test (Scenario 3) in `backend/tests/integration/brand_catalog_ingest.spec.ts`
- [X] T015 [P] Implement referral attribution integration test (Scenario 4) in `backend/tests/integration/referral_attribution.spec.ts`
- [X] T016 [P] Implement failure & observability smoke tests (Scenario 5) in `backend/tests/integration/platform_resilience.spec.ts`

## Phase 3.3: Core Implementation (after tests fail)
### Data Models
- [X] T017 [P] Create `UserProfileEntity` in `backend/src/modules/profiles/entities/user-profile.entity.ts`
- [X] T018 [P] Create `AvatarEntity` in `backend/src/modules/profiles/entities/avatar.entity.ts`
- [X] T019 [P] Create `BrandEntity` in `backend/src/modules/brand/entities/brand.entity.ts`
- [X] T020 [P] Create `BrandUserEntity` in `backend/src/modules/brand/entities/brand-user.entity.ts`
- [X] T021 [P] Create `ProductEntity` in `backend/src/modules/catalog/entities/product.entity.ts`
- [X] T022 [P] Create `ProductVariantEntity` in `backend/src/modules/catalog/entities/product-variant.entity.ts`
- [X] T023 [P] Create `SizeChartEntity` in `backend/src/modules/catalog/entities/size-chart.entity.ts`
- [X] T024 [P] Create `FitMapEntity` in `backend/src/modules/catalog/entities/fit-map.entity.ts`
- [X] T025 [P] Create `OrderEntity` in `backend/src/modules/commerce/entities/order.entity.ts`
- [X] T026 [P] Create `OrderItemEntity` in `backend/src/modules/commerce/entities/order-item.entity.ts`
- [X] T027 [P] Create `AddressEntity` in `backend/src/modules/common/entities/address.entity.ts`
- [X] T028 [P] Create `PaymentMethodEntity` in `backend/src/modules/commerce/entities/payment-method.entity.ts`
- [X] T029 [P] Create `ReferralEntity` in `backend/src/modules/referrals/entities/referral.entity.ts`
- [X] T030 [P] Create `ReferralEventEntity` in `backend/src/modules/referrals/entities/referral-event.entity.ts`
- [X] T031 [P] Create `EventLogEntity` in `backend/src/modules/audit/entities/event-log.entity.ts`
- [X] T032 [P] Create `RewardLedgerEntryEntity` in `backend/src/modules/referrals/entities/reward-ledger-entry.entity.ts`

### Services & Domain Logic
- [ ] T033 Implement auth service flows (signup/login/refresh/logout) in `backend/src/modules/auth/auth.service.ts`
- [ ] T034 Implement profile service (profile updates, data export/delete) in `backend/src/modules/profiles/profile.service.ts`
- [ ] T035 Implement avatar orchestration (generation queue + deletion) in `backend/src/modules/profiles/avatar.service.ts`
- [ ] T036 Implement try-on service (fit engine + render orchestration) in `backend/src/modules/tryon/tryon.service.ts`
- [ ] T037 Implement cart & checkout services in `backend/src/modules/commerce/cart.service.ts`
- [ ] T038 Implement order lifecycle & notification service in `backend/src/modules/commerce/orders.service.ts`
- [ ] T039 Implement brand catalog ingest + validation service in `backend/src/modules/brand/catalog.service.ts`
- [ ] T040 Implement referral service (RID issuance, validation, rewards) in `backend/src/modules/referrals/referral.service.ts`
- [ ] T041 Implement analytics aggregation service in `backend/src/modules/analytics/analytics.service.ts`

### Controllers & Resolvers
- [ ] T042 Wire auth controllers/guards per contracts in `backend/src/modules/auth/auth.controller.ts`
- [ ] T043 Wire profile + data rights controller in `backend/src/modules/profiles/profile.controller.ts`
- [ ] T044 Wire avatar controller & status endpoints in `backend/src/modules/profiles/avatar.controller.ts`
- [ ] T045 Wire try-on controller (sync + async polling) in `backend/src/modules/tryon/tryon.controller.ts`
- [ ] T046 Wire cart & checkout controllers in `backend/src/modules/commerce/checkout.controller.ts`
- [ ] T047 Wire orders controller & webhook dispatcher in `backend/src/modules/commerce/orders.controller.ts`
- [ ] T048 Wire brand portal controllers (catalog, size charts, fit maps, analytics) in `backend/src/modules/brand/brand.controller.ts`
- [ ] T049 Wire referrals controller & validation endpoint in `backend/src/modules/referrals/referral.controller.ts`
- [ ] T050 Implement PSP webhook controller (payment intents, payout events) in `backend/src/modules/commerce/webhooks.controller.ts`

### Workers & Jobs
- [ ] T051 Implement avatar processor worker in `backend/queue-workers/avatar-processor/src/index.ts`
- [ ] T052 Implement try-on renderer worker in `backend/queue-workers/tryon-renderer/src/index.ts`
- [ ] T053 Implement rewards ledger settlement job in `backend/src/modules/referrals/jobs/reward-ledger.job.ts`

### Frontend Core Flows
- [ ] T054 Build shopper try-on + checkout pages in `frontend/apps/shopper/src/app/(flows)/try-on/page.tsx`
- [ ] T055 Build shopper account/profile management in `frontend/apps/shopper/src/app/account/page.tsx`
- [ ] T056 Build brand catalog management UI in `frontend/apps/brand-portal/src/app/catalog/page.tsx`
- [ ] T057 Build brand analytics dashboard in `frontend/apps/brand-portal/src/app/analytics/page.tsx`
- [ ] T058 Build shopper referral sharing UI in `frontend/apps/shopper/src/app/referrals/page.tsx`

## Phase 3.4: Integration
- [ ] T059 Configure TypeORM module + migrations for all entities in `backend/src/database/migrations/`
- [ ] T060 Wire KMS-backed encryption utilities in `backend/src/lib/security/encryption.service.ts`
- [ ] T061 Integrate Stripe payment gateway + webhook signature verification in `backend/src/modules/commerce/payment.gateway.ts`
- [ ] T062 Integrate SQS client and message contracts in `backend/src/lib/queue/sqs-client.ts`
- [ ] T063 Implement OpenTelemetry tracing & metrics bootstrap in `backend/src/lib/observability/otel.ts`
- [ ] T064 Add Redis caches for sessions and try-on render caching in `backend/src/lib/cache/redis.client.ts`
- [ ] T065 Implement rate limiting & device fingerprint middleware in `backend/src/middleware/security/rate-limit.middleware.ts`
- [ ] T066 Implement media AV scanning pipeline in `backend/src/lib/media/scan-worker.ts`
- [ ] T067 Implement audit logging service hooks in `backend/src/modules/audit/event-log.service.ts`
- [ ] T068 Integrate referral rewards ledger persistence + scheduler in `backend/src/modules/referrals/reward-ledger.service.ts`
- [ ] T069 Configure frontend API client SDK using contracts in `frontend/packages/api-client/src/index.ts`
- [ ] T070 Hook frontend telemetry + consent banners in `frontend/packages/ui/src/components/TelemetryProvider.tsx`

## Phase 3.5: Polish & Validation
- [ ] T071 [P] Add unit tests for auth/profile services in `backend/tests/unit/services/auth-profile.service.spec.ts`
- [ ] T072 [P] Add unit tests for try-on/commerce services in `backend/tests/unit/services/tryon-commerce.service.spec.ts`
- [ ] T073 [P] Add unit tests for referral/brand services in `backend/tests/unit/services/referral-brand.service.spec.ts`
- [ ] T074 [P] Add frontend component tests for try-on widget in `frontend/apps/shopper/tests/unit/tryon-widget.spec.tsx`
- [ ] T075 Execute k6 performance test for try-on SLA in `load-tests/tryon/k6-script.js`
- [ ] T076 Perform security & threat model review update in `docs/security/fittwin-v1-threat-model.md`
- [ ] T077 Update API + developer docs in `docs/api/fittwin-v1.md`
- [ ] T078 Publish observability dashboards & alerts in `infra/observability/dashboards/tryon.json`
- [ ] T079 Complete release readiness checklist in `docs/release-checklists/fittwin-v1.md`

## Dependencies
- Phase 3.1 tasks (T001–T004) must complete before any tests.
- Contract & integration tests (T005–T016) must be authored and failing before Phase 3.3 tasks begin.
- Entity model tasks (T017–T032) unblock corresponding service implementations (T033–T041) and migrations (T059).
- Service tasks precede controller tasks within the same module (e.g., T037 → T046, T038 → T047).
- Queue workers (T051–T053) depend on try-on/referral services (T036, T040).
- Integration tasks (T059–T070) depend on core services/controllers being in place.
- Polish tasks (T071–T079) run only after integration work completes and core tests pass.

## Parallel Execution Examples
```
# Example 1: Author contract tests in parallel
/tasks run T005
/tasks run T006
/tasks run T007
/tasks run T008
/tasks run T009
/tasks run T010

# Example 2: Implement independent data models concurrently
/tasks run T019
/tasks run T021
/tasks run T025
/tasks run T029

# Example 3: Frontend feature work in parallel once APIs ready
/tasks run T054
/tasks run T056
/tasks run T058
```

## Validation Checklist
- [x] Every contract file mapped to a contract test task.
- [x] Every entity from data-model.md assigned a model creation task.
- [x] Tests (Phase 3.2) precede implementation tasks (Phase 3.3+).
- [x] [P] markers only on tasks with independent files/dependencies.
- [x] Each task provides an explicit file path or directory.
- [x] Polish tasks cover unit tests, performance, docs, and release readiness.
