#!/usr/bin/env bash
# Run CrewAI agents using OPENAI_API_KEY from environment (no .env file needed)
# Usage:
#   export OPENAI_API_KEY="sk-..."
#   export AGENT_MODEL="gpt-4o-mini"  # optional
#   ./scripts/run_agents_env.sh

set -euo pipefail

# Resolve repo root (this script lives under services/python/measurement/scripts)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
cd "$REPO_ROOT"

# Activate agents venv if present
if [ -f .venv-agents/bin/activate ]; then
  # shellcheck source=/dev/null
  source .venv-agents/bin/activate
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "ERROR: OPENAI_API_KEY environment variable is not set."
  echo "Set it with: export OPENAI_API_KEY=sk-..."
  exit 1
fi

echo "Starting agents bootstrap using OPENAI_API_KEY from environment..."
python3 -m ai.crewai.crew.bootstrap
