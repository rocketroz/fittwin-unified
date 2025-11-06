## AI Workloads

This directory hosts AI/ML automation tooling that complements the main stack.

- `crewai/` – CrewAI multi-agent workspace (agents, prompts, tools). Secrets and
  environment variables should live in `.env.example`; do not commit real keys.

Launch helpers live under `services/python/measurement/scripts/` alongside the
FastAPI service.
