# Cart, Checkout & Orders Contracts

## POST /cart/items
- **Auth**: Shopper access token.
- **Request**:
```json
{
  "productId": "uuid",
  "variantSku": "SKU-123",
  "qty": 1,
  "source": "tryon"
}
```
- **Responses**:
  - `201 Created`
    ```json
    {
      "cartId": "uuid",
      "itemId": "uuid",
      "item": {
        "productId": "uuid",
        "variantSku": "SKU-123",
        "name": "Relaxed Denim Jacket",
        "sizeLabel": "M",
        "qty": 1,
        "unitPrice": 12900,
        "currency": "USD",
        "recommended": true,
        "fitSummary": {"confidence": 88, "notes": ["waist snug"]}
      }
    }
    ```
  - `409 Conflict` — insufficient inventory.
  - `422 Unprocessable Entity` — invalid quantity or SKU not mapped to product.

## PATCH /cart/items/{itemId}
- Update `qty` or `variantSku`.
- **Responses**: `200 OK` with updated cart snapshot, `409` on inventory issues.

## DELETE /cart/items/{itemId}
- Response `204 No Content`.

## GET /cart
- Returns cart summary with pricing and recommendation nudges.
```json
{
  "cartId": "uuid",
  "items": [...],
  "totals": {
    "subtotal": 12900,
    "shipping": 0,
    "tax": 1032,
    "currency": "USD"
  },
  "recommendations": [
    {"productId": "uuid", "sizeRec": "M"}
  ]
}
```

## POST /checkout
- **Request**:
```json
{
  "cartId": "uuid",
  "paymentTokenId": "pm_123",
  "shippingAddressId": "uuid",
  "billingAddressId": "uuid",
  "rid": "optional-rid",
  "idempotencyKey": "uuid"
}
```
- **Responses**:
  - `201 Created`
    ```json
    {
      "orderId": "uuid",
      "status": "paid",
      "paymentIntentRef": "pi_123",
      "next": {
        "tracking": null,
        "brandFulfillmentEta": "2025-09-30"
      }
    }
    ```
  - `402 Payment Required` — PSP decline (include `declineCode`).
  - `409 Conflict` — idempotency replay with different payload.
  - `422 Unprocessable Entity` — missing address, RID invalid/expired.

## POST /checkout/confirm
- Handle async confirmation (3DS completion). Receives `paymentIntentRef` + status.  
- Response `204`.

## GET /orders
- Query params: `status`, `page`, `pageSize` (max 50).
- Response `200 OK` list with `totalCount` and pagination cursor.

## GET /orders/{orderId}
- Response includes items, totals, timeline, shipping provider, event log excerpts.

## POST /orders/{orderId}/return-request
- **Request**:
```json
{
  "items": [
    {"orderItemId": "uuid", "reason": "too_small"}
  ],
  "requestedAt": "2025-10-05T12:00:00Z"
}
```
- **Responses**: `201 Created` (return request logged, instructions emailed), `409 Conflict` if return window elapsed, `422` for invalid item.

## Webhooks (Outbound)
- `orders.sent_to_brand`
- `orders.fulfilled`
- `orders.delivered`
- `orders.return_requested`

Each webhook payload mirrors `GET /orders/{id}` with `eventType` and signature header.

## Error Codes
- `CART_NOT_FOUND`, `SKU_UNAVAILABLE`, `PAYMENT_DECLINED`, `RID_INVALID`, `SHIPPING_ADDRESS_REQUIRED`.

## Idempotency
- `/checkout` requires `Idempotency-Key` header (UUID). Server stores request hash for 24h.

## Audit & Notifications
- Checkout success triggers email/SMS (if consented) within 60 seconds.  
- All order status changes recorded in `event_logs` with actor `system` or `brand_admin`.
