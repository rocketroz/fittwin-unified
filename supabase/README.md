# Supabase Assets

Central location for database migrations, seed data, and operational docs that
previously lived in the CrewAI and unified repositories.

Imported content:

- `migrations/` – SQL from the unified platform (`003`–`007`) covering commerce,
  brands, referrals, and auth enhancements.
- `ENTITY_MAPPING.md` – checklist for reconciling Nest entities with the schema.

Next steps:

- Wire Supabase CLI scripts into the root tooling.
- Update TypeORM entities to match the migrations (see `ENTITY_MAPPING.md`).
