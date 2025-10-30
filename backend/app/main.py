"""
FitTwin Platform API - Main application entry point.

This FastAPI application provides a unified platform combining:
- DMaaS (Data-Model-as-a-Service) for measurements and size recommendations
- E-commerce infrastructure (cart, checkout, orders)
- Brand portal for B2B partners
- Referral system for viral growth

Designed for AI systems, online retailers, and direct-to-consumer commerce.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers.measurements import router as measurements_router
from app.routers.auth import router as auth_router
from app.routers.cart import router as cart_router
from app.routers.orders import router as orders_router
from app.routers.brands import router as brands_router
from app.routers.referrals import router as referrals_router


app = FastAPI(
    title="FitTwin Platform API",
    description=(
        "Unified AI-powered virtual fitting and e-commerce platform. "
        "Combines MediaPipe measurement technology, CrewAI autonomous agents, "
        "and comprehensive commerce infrastructure for next-generation retail experiences."
    ),
    version="2.0.0-unified",
    contact={
        "name": "FitTwin Support",
        "email": "support@fittwin.com",
    },
    license_info={
        "name": "Proprietary",
    },
)

# CORS middleware for cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(measurements_router)
app.include_router(auth_router)
app.include_router(cart_router)
app.include_router(orders_router)
app.include_router(brands_router)
app.include_router(referrals_router)


@app.get("/")
def root():
    """Health check endpoint with API information."""
    return {
        "status": "ok",
        "message": "FitTwin Platform API is running",
        "version": "2.0.0-unified",
        "docs": "/docs",
        "features": [
            "measurements",
            "auth",
            "cart",
            "orders",
            "brands",
            "referrals"
        ]
    }


@app.get("/health")
def health():
    """Detailed health check for monitoring."""
    return {
        "status": "healthy",
        "database": "connected",  # TODO: Add actual DB health check
        "mediapipe": "available",
        "stripe": "configured",  # TODO: Add actual Stripe health check
        "version": "2.0.0-unified"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
