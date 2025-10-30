# Try-On & Recommendation Contracts

## POST /tryon
- **Purpose**: Generate fit recommendation, confidence, and render imagery.
- **Auth**: Optional; accepts `avatarId` (logged-in) or `quickEstimate` fallback.
- **Request** (`application/json`):
```json
{
  "productId": "uuid",
  "variantSku": "SKU-123",
  "avatarId": "uuid",
  "quickEstimate": {
    "heightCm": 172,
    "weightKg": 68
  },
  "context": {
    "rid": "optional-rid",
    "channel": "web",
    "locale": "en-US"
  }
}
```
- **Responses**:
  - `200 OK`
    ```json
    {
      "images": [
        {"view": "front", "url": "https://signed-url", "expiresAt": "2025-09-23T14:30:00Z"}
      ],
      "sizeRec": {
        "label": "M",
        "confidence": 88,
        "notes": ["waist snug", "sleeve ideal"],
        "rationale": ["torso_balance", "user_style_pref"]
      },
      "altSizes": [
        {
          "label": "S",
          "fitDeltas": {"waist": "+5", "chest": "+2"},
          "confidence": 62
        }
      ],
      "processingTimeMs": 2400,
      "fitZones": {
        "waist": "snug",
        "hips": "ideal",
        "inseam": "ideal"
      }
    }
    ```
  - `202 Accepted` — cold start or heavy render queued; includes `tryOnId` for polling.
  - `400 Bad Request` — invalid avatar or missing measurements.
  - `404 Not Found` — product or variant not available.
  - `409 Conflict` — avatar in regeneration; instruct user to retry.

## GET /tryon/{tryOnId}
- Poll for asynchronous results if initial response was `202`.
- Responses mirror `POST /tryon` result; `202` while still processing; `410 Gone` if job expired.

## Telemetry Events
- `tryon.requested`: request metadata, latency target.
- `tryon.completed`: includes confidence, chosen size, alt sizes summary.
- `tryon.failed`: includes error code (`ASSET_MISSING`, `AVATAR_INVALID`, `TIMEOUT`).

## Validation Rules
- Requires either `avatarId` or `quickEstimate`; not both null.  
- Blocks try-on if product lacks size chart or fit map; returns `409` with remediation message.  
- Enforces RID TTL when provided (otherwise strips for analytics only).

## Caching Strategy
- Cache last successful render per (`avatarId`, `productId`, `variantSku`) combination for 12 hours (invalidated on avatar regeneration or product asset update).  
- Provide `cacheHit` boolean header for observability.
