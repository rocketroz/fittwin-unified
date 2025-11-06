# UX Component Porting Guide

| Legacy source | Target workspace | Notes |
| --- | --- | --- |
| `reference/unified-web/src/pages/CartPage.tsx` | `apps/shopper` cart route | Port summary + promo code layout. |
| `reference/unified-web/src/pages/CheckoutPage.tsx` | `apps/shopper` checkout flow | Reuse payment stepper and order summary widget. |
| `reference/unified-web/src/pages/ReferralsDashboard.tsx` | future `apps/brand-portal` module | Provide baseline for referral analytics once API is live. |
| `reference/manus-web/src/features/capture` | NativeScript lab | Adapt camera capture UI + measurement validation hints. |
| `mobile/ios/FitTwinApp/FitTwinApp/Views/CaptureView.swift` | NativeScript lab or native shell | Mirror LiDAR guidance overlays. |

Track completed ports here and note any blockers (dependency gaps, API shape
changes, etc.).
