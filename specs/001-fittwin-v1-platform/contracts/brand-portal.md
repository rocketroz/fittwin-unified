# Brand Portal Contracts

## POST /brand/catalog/upload
- **Auth**: Brand admin token (`owner` or `manager`).
- **Request**:
```json
{
  "brandId": "uuid",
  "fileUrl": "https://signed-upload-url",
  "schemaVersion": "1.0"
}
```
- **Responses**:
  - `202 Accepted`
    ```json
    {
      "ingestId": "uuid",
      "status": "processing"
    }
    ```
  - `400 Bad Request` — schemaVersion unsupported.
  - `409 Conflict` — existing ingest job in progress.

## GET /brand/catalog/upload/{ingestId}
- Returns validation results: `processing`, `completed`, or `failed` with row-level error list.

## POST /brand/catalog/products
- Direct API ingest for headless integration.
- **Request** (batched array):
```json
{
  "brandId": "uuid",
  "products": [
    {
      "externalId": "abc123",
      "title": "Relaxed Denim Jacket",
      "description": "...",
      "category": "jackets",
      "assets": {...},
      "sizeChartId": "uuid",
      "fitMapId": "uuid",
      "variants": [
        {
          "sku": "SKU-123",
          "sizeLabel": "M",
          "color": "Indigo",
          "price": {"amount": 12900, "currency": "USD"},
          "inventory": 50
        }
      ]
    }
  ]
}
```
- **Responses**: `201 Created` with success + error counts; `207 Multi-Status` for partial failures (per record error array).

## POST /brand/sizecharts
- Create or update size charts.
- **Request**:
```json
{
  "brandId": "uuid",
  "garmentType": "jackets",
  "unitSystem": "metric",
  "measurementRules": {
    "waist": {"min": 70, "max": 120, "tolerance": 2},
    "chest": {...}
  },
  "gradingRules": {
    "sizeOrder": ["XS","S","M","L","XL"],
    "increments": {"chest": 4, "waist": 3}
  }
}
```
- **Responses**: `201 Created` or `200 OK` (upsert), `409 Conflict` if garmentType already locked by Fit Team.

## POST /brand/fitmaps
- Parameterizes fit adjustments.
- **Request**:
```json
{
  "brandId": "uuid",
  "garmentType": "jackets",
  "ruleSet": {
    "model": "parametric",
    "parameters": {
      "waistEase": 2.5,
      "hipEase": 1.5
    }
  },
  "confidenceModel": {
    "baseline": 80,
    "modifiers": [{"factor": "materialStretch", "delta": 5}]
  }
}
```
- **Responses**: `201 Created`, `400 Bad Request` for validation issues.

## POST /brand/assets/3d
- **Purpose**: Upload 3D garment files.
- **Request**:
```json
{
  "productId": "uuid",
  "assetUrl": "https://signed-upload-url",
  "format": "glb",
  "metadata": {
    "polyCount": 25000,
    "texture": "4k"
  }
}
```
- **Response**: `202 Accepted`; processing pipeline validates and associates with product.

## GET /brand/analytics
- Query parameters: `brandId`, `rangeStart`, `rangeEnd`, `granularity`.
- **Response**:
```json
{
  "range": {
    "start": "2025-09-01",
    "end": "2025-09-30"
  },
  "conversionRate": 0.045,
  "returnRate": 0.08,
  "fitAccuracy": 0.91,
  "referralAttribution": {
    "orders": 128,
    "gmv": 540000
  }
}
```

## Roles & Permissions
- `owner`: full access including analytics, catalog, brand settings.
- `manager`: catalog + inventory + analytics.
- `analyst`: analytics read-only.

## Error Codes
- `KYC_PENDING`, `CATALOG_SCHEMA_INVALID`, `ASSET_SCAN_FAILED`, `NOT_AUTHORIZED`, `FITMAP_REQUIRED`.

## Notifications
- Catalog ingest completion triggers email/webhook with summary.  
- Asset processing failure raises alert & logs to `event_logs` with actor `system`.
