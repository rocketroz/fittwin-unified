#!/bin/bash
# FitTwin Platform - Test Runner Script

set -e

echo "🧪 Running FitTwin Platform Tests..."

# Activate virtual environment
source .venv/bin/activate

# Set PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Run backend tests
echo ""
echo "📦 Running Backend Tests..."
pytest tests/backend/ -v --cov=backend --cov-report=term-missing

# Run agent tests
echo ""
echo "🤖 Running Agent Tests..."
pytest tests/agents/ -v --cov=agents --cov-report=term-missing

# Run linting
echo ""
echo "🔍 Running Code Quality Checks..."
black --check backend/ agents/
flake8 backend/ agents/

echo ""
echo "✅ All tests passed!"
