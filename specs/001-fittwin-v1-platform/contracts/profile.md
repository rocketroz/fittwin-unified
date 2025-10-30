# Shopper Profile & Avatar Contracts

## GET /me
- **Auth**: Bearer access token.  
- **Response** `200 OK`:
```json
{
  "userId": "uuid",
  "email": "user@example.com",
  "username": "fitfan",
  "appearance": {
    "hairColor": "brown",
    "eyeColor": "green",
    "skinTone": "medium"
  },
  "stylePreferences": {
    "keywords": ["minimal", "athleisure"],
    "fitPrefs": {"tops": "normal", "bottoms": "slim"},
    "torsoLengthPref": "longer"
  },
  "bodyMetrics": {
    "heightCm": 172,
    "weightKg": 68,
    "measurements": {
      "waist": 74,
      "inseam": 80
    }
  },
  "avatars": [
    {
      "avatarId": "uuid",
      "version": 2,
      "status": "ready",
      "confidence": 88,
      "generatedAt": "2025-09-20T10:22:00Z"
    }
  ],
  "addresses": [...],
  "paymentMethods": [...],
  "consents": {
    "terms": true,
    "marketing": false,
    "dataExportAvailable": true
  }
}
```

## PUT /me/profile
- **Purpose**: Update optional identity/appearance/style fields.
- **Request**:
```json
{
  "appearance": {...},
  "stylePreferences": {...},
  "username": "fitfan"
}
```
- **Responses**: `200 OK` with merged profile, `400` validation, `409` username conflict.

## PUT /me/body
- **Purpose**: Persist height, weight, and measurement updates (SI units).
- **Request**:
```json
{
  "heightCm": 175,
  "weightKg": 70,
  "measurements": {
    "waist": 76,
    "chest": 96,
    "inseam": 81
  }
}
```
- **Responses**: `200 OK` returns updated metrics, `422 Unprocessable Entity` if outside validation ranges, `409` if measurement conflicts with avatar job.

## POST /me/avatar
- **Purpose**: Submit avatar sources and trigger generation job.
- **Request** (multipart metadata or JSON with signed uploads):
```json
{
  "sources": {
    "height": 172,
    "weight": 68,
    "measurements": {...},
    "photos": [
      {"url": "https://upload-url", "view": "front"},
      {"url": "https://upload-url", "view": "side"}
    ]
  }
}
```
- **Responses**:
  - `202 Accepted` with job status
    ```json
    {"avatarId": "uuid", "status": "processing"}
    ```
  - `409 Conflict` if another avatar job in-flight.

## GET /me/avatar/{avatarId}
- **Purpose**: Poll avatar status.
- **Response** `200 OK`:
```json
{
  "avatarId": "uuid",
  "status": "ready",
  "meshUrl": "https://signed-url",
  "confidence": 90,
  "generatedAt": "2025-09-20T10:30:00Z"
}
```
- **Errors**: `404` if avatar not found/belongs to another user.

## DELETE /me/avatar/{avatarId}
- Soft-deletes avatar and purges renders.  
- Responses: `204 No Content`, `409 Conflict` if avatar used by active order (prevent deletion until order delivered), `404 Not Found`.

## POST /me/payment-methods
- Integrates with Stripe Setup Intent.
- **Request**:
```json
{
  "paymentMethodId": "pm_123",
  "billingAddressId": "uuid"
}
```
- **Response** `201 Created` with stored token metadata; `402 Payment Required` if PSP validation fails.

## POST /me/addresses
- **Request**: shipping/billing address payload with ISO country.
- **Response**: `201 Created` returns normalized address.
- **Validation**: Format per country, AVS check (if payment-related). Errors `422` (invalid format).

## POST /me/export
- **Purpose**: Initiate data export bundle.
- **Response** `202 Accepted` with job reference; follow-up email when ready.

## DELETE /me
- **Purpose**: DSR delete request (soft delete + data purge pipeline).  
- **Response** `202 Accepted`; subsequent status via email.

### Common Error Schema
Same as Auth service. Additional `error.details` array for field-level validation.

### Security & Audit
- Every mutation logs to `event_logs` with actor = shopper.  
- Avatar upload URLs expire within 15 minutes; service enforces content-type + AV scanning.
