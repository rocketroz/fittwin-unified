# Developer setup — FitTwin

Step-by-step recipe for reproducing the local environment used in CI. Commands assume macOS/Linux with a working shell.

## Prerequisites
- Node.js 18+ and npm
- Python 3.11 or 3.12 (for the FastAPI measurement service + CrewAI agents)
- Postgres 14+ (local docker/container) *or* a Supabase project
- git

## 1. Clone & install dependencies
```bash
git clone <repo-url> fittwin
cd fittwin

# Node workspaces
npm install

# FastAPI + CrewAI service
cd services/python/measurement
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
deactivate
```

## 2. Pick a database mode
We support two Postgres targets. The backend reads `DATABASE_MODE` to decide how to connect.

### Local Postgres
```bash
createdb fittwin
psql fittwin < supabase/migrations/003_commerce_tables.sql
psql fittwin < supabase/migrations/004_brand_tables.sql
psql fittwin < supabase/migrations/005_referral_tables.sql
psql fittwin < supabase/migrations/006_auth_enhancements.sql
psql fittwin < supabase/migrations/007_referrals_and_brand_admins.sql

export DATABASE_MODE=local
export DATABASE_URL=postgres://fit:fit@localhost:5432/fittwin
```

### Supabase
```bash
export DATABASE_MODE=supa
export DATABASE_URL="postgres://<service-role-user>:<service-role-key>@<project>.supabase.co:5432/postgres"
export SUPABASE_CA_CERT="$(cat path/to/supabase-ca.pem)"    # optional if you need pinned CA
```

> Tip: the launcher script defaults to `DATABASE_MODE=local` if unset.

## 3. Start the stack
```bash
# back at repo root
npm run dev:stack
# Output: [dev-stack] Starting FitTwin stack (database mode: local). Press Ctrl+C to stop.
```

This boots:
- Nest backend (`backend/`, port `BACKEND_PORT` or 3000)
- Shopper Next.js app (`frontend/apps/shopper`, port 3001)
- Brand portal (`frontend/apps/brand-portal`, port 3100)

Ensure your Postgres instance is running before launching.

## 4. Run tests
```bash
# Node workspace tests
npm run test

# Full suite (Node + FastAPI + CrewAI)
npm run test:full
```

`npm run test:full` runs turborepo tests, then executes `services/python/measurement/scripts/test_all.sh`, which respects `.env.test` inside that folder.

## 5. FastAPI + CrewAI utilities
```bash
cd services/python/measurement
source .venv/bin/activate

# API dev server (FastAPI)
bash scripts/dev_server.sh

# CrewAI agent smoke suite
bash scripts/test_all.sh
```

`scripts/run_agents_env.sh` (same directory) bootstraps `.venv-agents`, validates `OPENAI_API_KEY`, and launches the measurement crew.

## Troubleshooting
- *TypeORM can’t connect*: confirm `DATABASE_URL` matches your `DATABASE_MODE`; local mode shouldn’t include SSL settings.
- *pytest complains about httpx/starlette*: recreate the virtualenv with `requirements-dev.txt`.
- *CrewAI auth failures*: ensure `OPENAI_API_KEY` is set (or provide a stub and disable imports via `DISABLE_CREWAI_IMPORTS=1` in `.env.test`).

## Helpful links
- Supabase setup guide: `docs/ops/supabase_setup_guide.md`
- Database entity mapping checklist: `supabase/ENTITY_MAPPING.md`
- Codex session logging: `docs/ops/codex_session_logging.md`
- Pause/resume workflow: `docs/ops/monorepo_ops.md`

— Updated November 2025
