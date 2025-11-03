# Merge CrewAI Measurement Stack into Unified Monorepo

## Summary

This PR merges the `merge-crew-ai` integration branch into `main`. It brings the CrewAI measurement workflow, refreshed backend services, iOS LiDAR capture flow, Supabase schema changes, and the legacy web experience into the shared monorepo. The result preserves the measurement agents’ capabilities while aligning environments, documentation, and CI so backend APIs, agents, and clients ship from a single repository.

## Highlights

- **CrewAI Agents**
  - Ports measurement crew bootstrap, client API, and shared tools into `agents/`
  - Adds `.env.example` scaffolding plus `scripts/run_agents.sh` and `scripts/run_agents_env.sh`
  - Introduces pytest coverage for measurement tool wiring in `tests/agents/`
- **Backend Enhancements**
  - Updates configuration, validation helpers, and measurement routers for CrewAI payloads
  - Adds Supabase provenance migration and backend-specific `requirements.txt`
  - Documents operations via `docs/AGENTS_BACKEND_NOTES.md`, `docs/deployment_guide.md`, and refreshed onboarding guides
- **iOS Capture Flow**
  - Integrates camera session controller, LiDAR measurement calculator, and new `CapturedPhoto` model
  - Refreshes `FitTwinAPI` client plus Info.plist entitlements to target the unified backend
- **Frontend & Legacy Web**
  - Imports legacy Manus web client and supporting UI component library
  - Adds capture stub under `frontend/src/photoCaptureStub.js` to unblock experiments
- **Automation & CI**
  - Adds GitHub workflows for backend + monorepo CI
  - Normalizes `scripts/dev_server.sh` and `scripts/test_all.sh` to operate from the unified layout
- **Docs & Assets**
  - Adds merge diary `CrewAIMerge.log`, ops handbook `FITWIN_MONOREPO_OPS.md`, deployment guides, and prompt archives
  - Captures screenshots cataloging capture UX and QA checkpoints

## Testing

| Suite | Command | Result |
| --- | --- | --- |
| Backend + Agents | `bash scripts/test_all.sh` | ✅ 21 tests, warnings only |

> Backend suite covers carts, measurements, and validation endpoints; agent suite exercises measurement tools and client API wrappers.

### Optional Manual QA

```bash
# Backend API smoke (requires backend .env)
bash scripts/dev_server.sh
curl -s -X POST http://127.0.0.1:8000/measurements/validate \
  -H "Content-Type: application/json" \
  -H "X-API-Key: <local-api-key>" \
  -d '{"height_cm": 172, "waist_natural_cm": 80, "source": "mediapipe"}' | python -m json.tool

# CrewAI agent workflow (after sourcing scripts/run_agents_env.sh)
bash scripts/run_agents.sh --crew measurement
```

## Metrics

- **Files changed:** 281
- **Lines added:** ~26k
- **Lines removed:** ~1k
- **Assets added:** iOS LiDAR sources, legacy web UI, screenshots, system prompts

## Risks & Mitigations

| Risk | Mitigation |
| --- | --- |
| Environment drift between backend and agents | Shared `.env.example` templates and run scripts |
| MediaPipe compatibility on Apple Silicon | Pinned dependency `mediapipe==0.10.9` verified under Python 3.11 |
| Large binary assets inflating clone size | Documented in `CrewAIMerge.log`; consider artifact storage follow-up |
| CI secret requirements | Workflows scoped to lint/test only; deployment secrets unchanged |

### Breaking / Notable Changes
- Backend service stubs (brands, cart, orders) remain partially implemented; coverage report documents TODOs
- iOS project assumes LiDAR-capable devices; gating handled by `DeviceRequirementChecker`
- Legacy Manus web assets are included for reference and aren’t wired into production deploys

## Rollback Plan

```bash
# Revert merge commit
git revert -m 1 <merge-commit>
git push origin main

# Or reset branch if hotfix needed
git checkout main
git reset --hard origin/main~1
git push -f origin main
```

## Deployment Checklist

Before merging:
- [ ] Secrets available for backend `.env`, agents `.env`, and iOS Info.plist
- [ ] QA pass of capture flow against staging backend
- [x] `bash scripts/test_all.sh`

After merging:
- [ ] Apply Supabase migration `002_measurement_provenance.sql`
- [ ] Update iOS provisioning profiles if bundle IDs changed
- [ ] Communicate new docs and agent workflows to cross-functional teams

## Follow-ups

- Expand backend service coverage now that scaffolding is in place
- Enable linting in CI once outstanding issues are addressed (`RUN_LINT=1`)
- Trim or externalize large screenshot assets before release packaging
- Schedule end-to-end capture test across iOS app → backend → CrewAI workflow

---

**Ready to merge:** ✅ Yes  
**Blocking issues:** ⚠️ Ensure environment secrets available for QA  
**Tests executed:** ✅ `bash scripts/test_all.sh`
