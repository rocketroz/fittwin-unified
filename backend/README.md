# FitTwin Platform - Backend API

This directory contains the FastAPI backend for the FitTwin Platform. It provides a unified API for measurement extraction, e-commerce, brand management, and more.

## Getting Started

### Prerequisites

- Python 3.11+
- Pip and a virtual environment tool (e.g., `venv`)
- Access to a Supabase project
- An OpenAI API key (for CrewAI agents)

### 1. Environment Setup

1.  Navigate to the project root and create a Python virtual environment:
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate
    ```

2.  Install the required Python dependencies:
    ```bash
    pip install -r requirements-dev.txt
    ```

3.  Copy the environment template and fill in your credentials:
    ```bash
    cp backend/.env.example backend/.env
    ```

    **Edit `backend/.env`** with your Supabase, Stripe, and JWT secret details.

### 2. Running the Development Server

From the project root, you can run the backend using the development script:

```bash
bash scripts/dev_server.sh
```

This will start the FastAPI server with hot-reloading enabled at `http://localhost:8000`.

### 3. API Documentation

Once the server is running, you can access the interactive API documentation (Swagger UI) at:

[http://localhost:8000/docs](http://localhost:8000/docs)

## Testing

To run the backend tests, execute the following command from the project root:

```bash
pytest tests/backend/ -v
```

## Deployment

This FastAPI application is designed for easy deployment to modern cloud platforms like Railway, Fly.io, or Render.

### Railway

```bash
railway login
railway init
railway up
```

### Fly.io

```bash
fly launch
fly deploy
```

Ensure that you have set up the required environment variables in your chosen platform's dashboard.
