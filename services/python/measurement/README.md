# Measurement Service (FastAPI)

This folder contains the FastAPI implementation imported from the unified repo.
It exposes the DMaaS `/measurements/validate` and `/measurements/recommend`
endpoints, along with cart/order/referral logic that will be ported into the
Nest stack.

## Getting Started

```bash
cd services/python/measurement
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env
cp .env.test .env.test.local  # optional overrides for pytest
export PYTHONPATH="${PYTHONPATH}:$(pwd):$(pwd)/backend"
uvicorn backend.app.main:app --reload --port 8000
```

Run tests with:

```bash
./scripts/test_all.sh
```

Once the Nest modules absorb the functionality, this service can shrink back to
measurement-only responsibilities or be retired entirely.

### Useful Scripts

- `scripts/dev_server.sh` — boots the FastAPI backend with autoreload.
- `scripts/test_all.sh` — exercises backend + agent suites; honours `.env.test`.
- `scripts/run_agents_env.sh` — activates `.venv-agents`, checks secrets, then
  launches the CrewAI measurement crew.
- `scripts/log_codex_session.py` — helper to capture Codex collaboration logs
  (see `docs/ops/codex_session_logging.md`).
