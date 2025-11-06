# FitTwin Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-09-23

## Active Technologies
- (001-fittwin-v1-platform)
- CrewAI multi-agent workflows (imported; see `ai/crewai` and `services/python/measurement/scripts`)

## Project Structure
```
backend/
frontend/
tests/
ai/            # CrewAI workspace
services/      # FastAPI measurement service and future non-Node workloads
supabase/      # Shared migrations and ops docs
docs/          # Consolidated knowledge base
```

## Commands
- `python ai/crewai/crew/measurement_crew.py` – run the measurement crew directly.
- `services/python/measurement/scripts/run_agents_env.sh` – helper for sourcing `.env`, ensuring `.venv-agents`, then launching crews.

## Code Style
: Follow standard conventions; the CrewAI code continues to use Python 3.11 typing and black/ruff defaults.

## Recent Changes
- 001-fittwin-v1-platform: Added.
- CrewAI + Manus documentation staged for import.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
