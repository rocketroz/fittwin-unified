# Auth Service Contracts

## POST /auth/signup
- **Purpose**: Register a shopper account, trigger email verification, store password hash with breach check.
- **Request** (`application/json`):
```json
{
  "email": "user@example.com",
  "password": "StrongPass!42",
  "consent": {
    "terms": true,
    "marketing": false,
    "privacy": true
  }
}
```
- **Responses**:
  - `202 Accepted`
    ```json
    {
      "userId": "uuid",
      "status": "verification_pending"
    }
    ```
  - `400 Bad Request` — validation errors (weak password, missing consent).
  - `409 Conflict` — email already registered.
- **Side Effects**: writes `user_profiles`, emits verification email event, logs audit entry.

## POST /auth/verify
- **Purpose**: Confirm email verification token.
- **Request** (`application/json`):
```json
{
  "token": "verification-token"
}
```
- **Responses**:
  - `204 No Content` on success.
  - `400 Bad Request` — token malformed/expired.
  - `404 Not Found` — token not recognized.

## POST /auth/login
- **Purpose**: Authenticate user credentials and issue tokens.
- **Request**:
```json
{
  "email": "user@example.com",
  "password": "StrongPass!42",
  "device": {
    "name": "Safari on Mac",
    "fingerprint": "hash"
  }
}
```
- **Responses**:
  - `200 OK`
    ```json
    {
      "accessToken": "jwt",
      "refreshToken": "opaque-refresh-token",
      "expiresIn": 900,
      "mfaRequired": false
    }
    ```
  - `401 Unauthorized` — bad credentials or breached password.
  - `423 Locked` — too many failed attempts (rate limit).

## POST /auth/refresh
- **Purpose**: Rotate refresh token for continued sessions.
- **Request**:
```json
{
  "refreshToken": "opaque-refresh-token",
  "deviceFingerprint": "hash"
}
```
- **Responses**:
  - `200 OK`
    ```json
    {
      "accessToken": "jwt",
      "refreshToken": "new-opaque-token",
      "expiresIn": 900
    }
    ```
  - `401 Unauthorized` — invalid/expired token.
  - `409 Conflict` — fingerprint mismatch.

## POST /auth/logout
- **Purpose**: Invalidate refresh token for current device.
- **Request**:
```json
{
  "refreshToken": "opaque-refresh-token"
}
```
- **Responses**: `204 No Content` or `401 Unauthorized` if token already revoked.

## Error Schema
```json
{
  "error": {
    "code": "string",
    "message": "human readable",
    "field": "optional"
  }
}
```

## Rate Limits
- `/auth/signup`: 5 attempts / hour per IP + email.
- `/auth/login`: 10 attempts / 15 minutes per device fingerprint.

## Security
- All endpoints require HTTPS.  
- Responses set `Set-Cookie` for optional session tracking (httpOnly) without auth data.
