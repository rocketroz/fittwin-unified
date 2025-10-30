# Implementation Plan: FitTwin v1 Platform

**Branch**: `001-fittwin-v1-platform` | **Date**: 2025-09-23 | **Spec**: /Users/kroma/FitTwin/specs/001-fittwin-v1-platform/spec.md  
**Input**: Feature specification from `/specs/001-fittwin-v1-platform/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

## Summary
FitTwin v1 delivers an integrated shopper journey: account creation, AI twin generation, confidence-backed virtual try-on, tokenized checkout, brand catalog onboarding, and referral attribution. The plan preserves privacy-by-design, PCI SAQ A compliance, and observability so brands reduce returns and shoppers trust recommendations.

## Technical Context
**Language/Version**: Backend — Node.js 20 (TypeScript, NestJS services); Frontend — React/Next.js 14 with shared component library.  
**Primary Dependencies**: NestJS + Fastify adapters, PostgreSQL 15, Redis 7, Stripe Payments/Billing, AWS S3 for media, AWS SQS for async jobs, OpenTelemetry SDK, SendGrid for comms.  
**Storage**: PostgreSQL for transactional data (partitioned orders/event logs); Redis for sessions/rate-limit counters; S3 buckets for avatars/renders/assets with AV scanning.  
**Testing**: Jest (unit), Supertest (contract/API), Pactflow for consumer contracts, Playwright (end-to-end shopper/brand flows), k6 for try-on latency smoke.  
**Target Platform**: Containerized web stack (Kubernetes) serving shopper web app + brand portal over CDN; backend services exposed via API gateway.  
**Project Type**: web (frontend + backend services).  
**Performance Goals**: Try-on ≤3.0s warm / ≤6.0s cold; avatar generation ≤30s P95; PDP TTI ≤2.5s on 4G device; checkout success ≥98% (non-funds failures).  
**Constraints**: PCI SAQ A boundary, field-level PII encryption (KMS envelope), audit logging for admin/brand actions, explicit data export/delete, referral fraud heuristics.  
**Scale/Scope**: Launch target 50k MAU, 20 pilot brands, peak try-on throughput 200 req/s warm with queue-based burst handling.

## Constitution Check
- **Privacy & Data Rights**: Data-model + contracts enforce export/delete endpoints, encrypted PII, signed media URLs.  
- **Fit Transparency**: Try-on contract guarantees sizeRec, confidence, fit notes, alternate sizes.  
- **Secure Commerce**: Checkout contract maintains PSP token usage, order state machine, consented notifications.  
- **Brand Enablement**: Brand portal contracts cover catalog ingest, size chart mapping, analytics.  
- **Observability & Quality**: Research locks OpenTelemetry stack, quickstart scenario 5 validates error telemetry.

✅ Initial Constitution Check: PASS  
✅ Post-Design Constitution Check: PASS (data model + contracts retain privacy, fit, and PSP guarantees.)

## Project Structure

### Documentation (this feature)
```
specs/001-fittwin-v1-platform/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
backend/
├── src/
│   ├── modules/
│   │   ├── auth/
│   │   ├── profiles/
│   │   ├── tryon/
│   │   ├── commerce/
│   │   ├── referrals/
│   │   └── brand/
│   ├── lib/        # encryption, messaging, telemetry
│   └── main.ts
├── queue-workers/
│   ├── avatar-processor/
│   └── tryon-renderer/
└── tests/
    ├── unit/
    ├── contract/
    └── integration/

frontend/
├── apps/
│   ├── shopper/
│   └── brand-portal/
├── packages/
│   ├── ui/
│   ├── api-client/
│   └── analytics/
└── tests/
    ├── unit/
    └── e2e/

shared/
├── schema/      # zod/openapi schemas generated from contracts
└── infra/       # Terraform/Kubernetes manifests
```

**Structure Decision**: Option 2 (web application) with shared packages ensures clear separation of shopper/brand frontends and modular backend services.

## Phase 0: Outline & Research
1. **Unknowns & Clarifications Resolved**  
   - TC-1: Backend runtime set to Node.js/NestJS with modular services.  
   - TC-2: Try-on pipeline split between inference service + rendering worker on SQS.  
   - TC-3: Auth pattern defined (Argon2id, breach check, JWT + device-bound refresh).  
   - TC-4: PSP = Stripe with Setup/Payment Intents.  
   - TC-5: Observability via OpenTelemetry + structured logging.  
   - TC-6: Envelope encryption with KMS and field-level protection.  

2. **Research Highlights** (see `research.md`)  
   - Fit/render separation for SLA resilience.  
   - Stripe selected for tokenized payments + 3DS coverage.  
   - Data encryption + secrets rotation strategy documented.  
   - Observability stack vendor-neutral with PII redaction.  
   - Asset pipeline defined for signed URLs + AV scanning.

3. **Status**: ✅ `research.md` created with decisions, rationale, and alternatives.

## Phase 1: Design & Contracts
- `data-model.md` captures relational schema, indexes, and retention strategy.  
- `/contracts/` defines REST contracts for auth, profile, try-on, commerce, brand portal, and referrals (request/response schemas, errors).  
- `quickstart.md` documents 5 end-to-end scenarios (shopper happy path, avatar regeneration, brand ingest, referral attribution, failure smoke).  
- `.specify/scripts/bash/update-agent-context.sh codex` executed to refresh agent hints.  
- Constitution re-validated post-design (privacy, sizing, payments, observability) — no violations detected.

## Phase 2: Task Planning Approach
*To be executed via `/tasks`.*

- Use generated contracts & data model to create contract-first tests before implementation.  
- Parallelizable tasks: individual contract test files, UI component scaffolds, worker services.  
- Sequential tasks: data model migrations → repositories → service logic → API controllers.  
- Include dedicated tasks for encryption helper, Stripe integration mocks, OpenTelemetry instrumentation, and referral fraud heuristics.  
- Ensure polish tasks cover load testing try-on pipeline and documentation updates (API reference, admin handbook).

## Phase 3+: Future Implementation
- Phase 3 (`/tasks`): produce ordered tasks.md.  
- Phase 4: Implement services/tests per tasks.  
- Phase 5: Validate (run contract + integration suites, execute quickstart scenarios, latency smoke tests).

## Complexity Tracking
| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| _None_ |  |  |

## Progress Tracking
**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved (or assumptions recorded)
- [ ] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
