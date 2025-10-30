#!/bin/bash
# FitTwin Platform - CrewAI Agent Runner Script

set -e

echo "🤖 Starting FitTwin CrewAI Agents..."

# Activate virtual environment
source .venv/bin/activate

# Set PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"

# Check if .env exists
if [ ! -f "agents/.env" ]; then
    echo "⚠️  Warning: agents/.env file not found."
    echo "📝 Please create agents/.env with your OpenAI API key."
    exit 1
fi

# Run the measurement crew
echo "✅ Starting Measurement Crew..."
python agents/crew/measurement_crew.py
