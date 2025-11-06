# Reference Frontends

Artifacts migrated from the CrewAI/Manus and unified repos for component reuse.

- `manus-web/` – Vite/React build that exercised the legacy capture + sizing
  flows. Mine this for camera UX, measurement forms, and MediaPipe bindings when
  enhancing the Next.js shopper app.
- `unified-web/` – React client from the unified platform (cart, checkout,
  referrals dashboards). Use this code when porting reducers/components into the
  current workspace packages.

These projects are not part of the pnpm workspace. Install dependencies and run
them in isolation when referencing behaviour.
