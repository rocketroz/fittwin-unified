# Referral & Rewards Contracts

## POST /referrals
- **Auth**: Shopper token.
- **Request**:
```json
{
  "productId": "uuid",
  "channel": "social"
}
```
- **Responses**:
  - `201 Created`
    ```json
    {
      "rid": "b64urlhash",
      "shareUrl": "https://app.fittwin.com/p/slug?rid=b64urlhash",
      "expiresAt": "2025-10-23T00:00:00Z",
      "policy": {
        "rewardType": "storeCredit",
        "rewardValue": 1000,
        "currency": "USD",
        "holdDays": 30
      }
    }
    ```
  - `409 Conflict` — active RID already exists for product (returns existing data).

## GET /referrals/{rid}
- **Purpose**: Owner retrieves stats.
- **Response** `200 OK`:
```json
{
  "rid": "b64urlhash",
  "clicks": 42,
  "conversions": 5,
  "gmv": 215000,
  "status": "active",
  "expiresAt": "2025-10-23T00:00:00Z",
  "rewards": {
    "pendingHold": 3,
    "payable": 2,
    "paid": 0
  }
}
```
- **Errors**: `404` if RID not found or user not owner.

## GET /referrals/{rid}/events
- **Purpose**: List click and conversion events (paginated).
- **Response** `200 OK`:
```json
{
  "events": [
    {
      "eventId": "uuid",
      "eventType": "click",
      "timestamp": "2025-09-20T12:34:00Z"
    },
    {
      "eventId": "uuid",
      "eventType": "conversion",
      "timestamp": "2025-09-21T18:10:00Z",
      "orderId": "uuid",
      "orderTotal": 12900
    }
  ],
  "nextCursor": null
}
```

## POST /referrals/validate
- **Purpose**: Internal API invoked during checkout to validate RID.  
- **Request**:
```json
{
  "rid": "b64urlhash",
  "orderId": "uuid",
  "userId": "uuid",
  "deviceFingerprint": "hash",
  "ip": "hashed-ip"
}
```
- **Responses**:
  - `200 OK`
    ```json
    {
      "valid": true,
      "attribution": "first_click",
      "reason": null
    }
    ```
  - `409 Conflict` — RID expired or violates self-purchase policy (returns `valid: false`, `reason`).

## Fraud Controls
- Rate limit generating RIDs to 10/day per user.  
- Device/IP heuristics to spot multi-account abuse; flagged events produce `fraud_flag` event and notify platform admins.

## Rewards Ledger Sync
- Webhook `referral.reward_payable` triggers when return window lapses.
- Payload includes `rid`, `orderId`, `rewardAmount`, `currency`, `status`.

## Error Schema
- Same base error format with `error.code` values: `RID_EXPIRED`, `RID_REVOKED`, `RID_SELF_PURCHASE_BLOCKED`, `RID_RATE_LIMITED`.
