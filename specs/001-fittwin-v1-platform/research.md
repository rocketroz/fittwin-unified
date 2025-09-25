# Research Findings: FitTwin v1 Platform

## R-1: Try-On Architecture & Rendering Pipeline
**Decision**: Decompose try-on into a fit inference service (REST/gRPC) and an asynchronous rendering worker that writes signed image artifacts to object storage with cached warm renders.  
**Rationale**: Separating inference from rendering isolates CPU/GPU heavy work, enables horizontal scaling to meet 3s/6s SLAs, and allows queue-level retries without blocking PDP requests.  
**Alternatives Considered**: Monolithic synchronous rendering (rejected: risk of PDP timeout spikes); fully managed third-party try-on API (rejected: loss of control over fit confidence features and branding requirements).

## R-2: Identity & Session Management
**Decision**: Implement dedicated Auth service using Argon2id password hashing, Have-I-Been-Pwned-style breach checks, short-lived JWT access tokens (15 min), rotating refresh tokens stored per device with fingerprinting & revocation lists.  
**Rationale**: Aligns with constitution’s security mandates, supports device-level logout, and integrates with rate limiting + audit logging.  
**Alternatives Considered**: Outsourcing to auth SaaS (Auth0, Cognito) rejected to preserve data residency controls and custom breach policy; session cookies rejected for future native clients.

## R-3: PSP Integration
**Decision**: Use Stripe (Payments + Billing) in SAQ-A mode via Setup Intents for tokenization, Payment Intents for charges, with automatic 3DS orchestration and AVS checks; store only `paymentMethodId` and `paymentIntentId`.  
**Rationale**: Stripe meets global coverage, offers webhooks for order state transitions, and simplifies rewards ledger reconciliation while keeping raw card data out of scope.  
**Alternatives Considered**: Adyen (good multi-region but heavier onboarding) and Braintree (limited 3DS handling) set aside for later multi-PSP strategy.

## R-4: Data Encryption & Secrets Management
**Decision**: Adopt envelope encryption via KMS (AWS KMS or GCP Cloud KMS) with service-level data keys; apply field-level encryption for PII (phone, addresses) and tokenized vault for PSP references; rotate keys every 90 days with automated re-encryption job.  
**Rationale**: Provides repeatable compliance story, isolates keys from app servers, and supports future regional data residency.  
**Alternatives Considered**: Application-managed master secrets (higher operational risk), whole-database encryption only (insufficient field-level protection for PII exports).

## R-5: Observability Stack
**Decision**: Standardize on OpenTelemetry SDKs for backend services, emit structured JSON logs to ELK-compatible sink, metrics via Prometheus/OpenMetrics exporters, and tracing to Jaeger/Tempo with requestId propagation through try-on, checkout, and referrals.  
**Rationale**: Satisfies constitution requirement for tracing fit computations and checkout flows, keeps instrumentation vendor-neutral, and supports PII redaction filters.  
**Alternatives Considered**: Proprietary observability SaaS (higher vendor lock-in, data residency concerns). Plain logs without tracing (insufficient for latency SLAs).

## R-6: Asset & Media Handling
**Decision**: Store avatars, renders, brand 3D assets, and CSV uploads in private S3-compatible buckets; generate time-limited signed URLs for uploads/downloads and run AV scanning on inbound media via async lambda/worker.  
**Rationale**: Meets privacy/security requirements, supports region-based buckets, and avoids sending raw media through core services.  
**Alternatives Considered**: Serving assets via public CDN without signing (privacy risk); storing large assets in relational DB (storage inefficiency).

## Resolved Technical Context
- Backend runtime: TypeScript on Node.js 20 with service boundaries (auth, profile, try-on, commerce).  
- Frontend: React + Next.js for shopper & brand portals, shared design system.  
- Queue: Managed message queue (e.g., AWS SQS) for async avatar generation/render jobs.  
- Persistent store: PostgreSQL 15 for transactional data; Redis for session/queue dedupe cache.  
- Infrastructure baseline: Containerized services orchestrated via Kubernetes (EKS/GKE) with IaC; staging/prod parity.

No open research blockers remain; assumptions tracked in spec cover rewards policy integration.
