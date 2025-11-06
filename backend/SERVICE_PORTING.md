## Service Porting Map

This document tracks how the FastAPI services from the unified repo map into the
existing Nest modules.

| FastAPI module | Target Nest module | Notes |
| --- | --- | --- |
| `backend/app/services/cart_service.py` | `modules/commerce/cart.service.ts` | Replace in-memory store with Supabase persistence; port price calc + shipping logic. |
| `backend/app/services/order_service.py` | `modules/commerce/orders.service.ts` | Align order state machine, payment integration, and referral hooks. |
| `backend/app/services/referral_service.py` | `modules/referrals` (new) | Nest module currently stubbed; import rewards logic + fraud checks. |
| `backend/app/services/brand_service.py` | `modules/brand` | Port catalog ingest validation and analytics queries. |
| `backend/app/services/auth_service.py` | `modules/auth` | Consolidate password policy, breach check, refresh token store. |
| `backend/app/services/vendor_client.py` | `modules/tryon` + `modules/catalog` | Evaluate whether vendor integrations stay Python or become Nest providers. |

For each service:
1. Stage the Python implementation under `services/python/measurement/backend/app/services`.
2. Mirror the data contracts in TypeScript DTOs.
3. Replace the in-memory store with Supabase repos once migrations land.
