#!/bin/bash
# FitTwin Platform - Test Runner Script

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SERVICE_ROOT/../../.." && pwd)"

echo "🧪 Running FitTwin Platform Tests..."

# Activate virtual environment if available
if [ ! -f ".venv/bin/activate" ]; then
  echo "⚠️  .venv not present; skipping FastAPI + CrewAI tests."
  exit 0
fi

source .venv/bin/activate

if ! python -c "import fastapi" >/dev/null 2>&1; then
  echo "⚠️  fastapi not installed in .venv; skipping FastAPI + CrewAI tests."
  deactivate >/dev/null 2>&1 || true
  exit 0
fi

# Load test environment overrides if present
if [ -f ".env.test" ]; then
  set -a
  source .env.test
  set +a
fi

# Set PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:${SERVICE_ROOT}:${SERVICE_ROOT}/backend:${REPO_ROOT}:${REPO_ROOT}/agents"

# Run backend tests
echo ""
echo "📦 Running Backend Tests..."
pytest tests/backend/ -v --cov=backend --cov-report=term-missing

# Run agent tests
echo ""
echo "🤖 Running Agent Tests..."
pytest tests/agents/ -v --cov=agents --cov-report=term-missing

# Run linting
if [ "${RUN_LINT:-0}" -eq 1 ]; then
  echo ""
  echo "🔍 Running Code Quality Checks..."
  BLACK_TARGETS=("backend/app" "agents/client" "agents/config" "agents/prompts" "agents/tools")
  FLAKE_TARGETS=("backend/app" "agents/client" "agents/config" "agents/prompts" "agents/tools")
  black --check "${BLACK_TARGETS[@]}"
  flake8 "${FLAKE_TARGETS[@]}"
else
  echo ""
  echo "ℹ️  Skipping lint checks (set RUN_LINT=1 to enable)."
fi

echo ""
echo "✅ All tests passed!"
