#!/bin/sh
set -euo pipefail

echo "==> Running Node workspace tests"
npm run test

echo "==> Running FastAPI + CrewAI suite"
(
  cd services/python/measurement
  if [ ! -d ".venv" ]; then
    echo "    (warning) .venv not found; ensure dependencies are installed." >&2
  fi
  ./scripts/test_all.sh
)
