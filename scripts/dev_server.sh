#!/bin/bash
# FitTwin Platform - Development Server Script

set -e

echo "🚀 Starting FitTwin Platform Development Server..."

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "❌ Virtual environment not found. Creating one..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install dependencies if needed
if [ ! -f ".venv/installed" ]; then
    echo "📦 Installing dependencies..."
    pip install -r requirements-dev.txt
    touch .venv/installed
fi

# Set PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found. Copying from .env.example..."
    cp .env.example .env
    echo "📝 Please edit .env with your credentials before running the server."
    exit 1
fi

# Start the server
echo "✅ Starting FastAPI server on http://localhost:8000"
echo "📚 API docs available at http://localhost:8000/docs"
echo ""

uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
