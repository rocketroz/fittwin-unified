# GitHub Workflows Setup

Due to GitHub App permissions, the CI/CD workflow files need to be added manually to your repository.

## Workflow Files to Add

Create these files in `.github/workflows/` directory:

### 1. Backend Tests (`backend-tests.yml`)

```yaml
name: Backend Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        python-version: ["3.11"]

    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements-dev.txt
    
    - name: Run tests
      run: |
        export PYTHONPATH="${PYTHONPATH}:$(pwd)"
        pytest tests/backend/ -v --cov=backend
    
    - name: Run linting
      run: |
        black --check backend/
        flake8 backend/
```

### 2. Mobile Build (`mobile-build.yml`)

See the workflow files in the local `.github/workflows/` directory for complete configurations.

## Setup Instructions

1. Navigate to your repository on GitHub
2. Create `.github/workflows/` directory if it doesn't exist
3. Add the workflow YAML files manually
4. Commit and push

Or use the GitHub web interface to create workflows directly.
