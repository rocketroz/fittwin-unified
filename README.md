# FitTwin Platform

**A unified AI-powered virtual fitting and e-commerce platform combining MediaPipe measurement technology, CrewAI autonomous agents, and comprehensive commerce infrastructure.**

**Author:** Laura Tornga (@rocketroz)  
**Repository:** Merged from fittwindev/fittwin + rocketroz/fitwin-crewai  
**Version:** 2.0.0-unified

---

## Overview

FitTwin Platform is a next-generation virtual fitting solution that combines:

- **AI-Powered Development**: CrewAI multi-agent system for autonomous feature development
- **Free Measurement Technology**: MediaPipe Pose Landmarker for cost-effective, on-device extraction
- **Complete Commerce Stack**: Cart, checkout, orders, payments, and referral system
- **Dual-Platform Architecture**: Native iOS for measurement capture + web app for commerce
- **DMaaS Business Model**: Data-Model-as-a-Service API for AI systems and retailers
- **Brand Portal**: Multi-tenant B2B features for brand partners

---

## Key Features

### 🤖 **AI-Powered Development**
- **5-Agent CrewAI System**: CEO, Architect, ML Engineer, DevOps, Reviewer
- Autonomous error repair and escalation workflows
- Budget-conscious development (<$500 MVP target)
- Strategic directives aligned with DMaaS business model

### 📏 **Measurement Technology**
- **MediaPipe Integration**: Free, on-device pose landmark extraction
- Geometric anthropometric calculations
- Measurement provenance tracking (photos, landmarks, calculations)
- Optional vendor API calibration for <97% accuracy scenarios
- Confidence scoring and quality assessment

### 🛒 **E-Commerce Infrastructure**
- **Cart Management**: Add/update/remove with inventory validation
- **Checkout Flow**: Payment tokenization via PSP (Stripe)
- **Order Lifecycle**: Full state machine with notifications
- **Referral System**: Viral growth with attribution tracking
- **Address & Payment Management**: Secure tokenized storage

### 👔 **Virtual Try-On**
- Avatar generation from MediaPipe landmarks
- Queue-based rendering pipeline
- Fit zone analysis (waist, hips, inseam)
- Alternative size recommendations with deltas
- Confidence scoring for recommendations

### 🏢 **Brand Portal (B2B)**
- Brand onboarding and KYC workflows
- Catalog CSV/API ingest with validation
- Size chart and fit map management
- Performance analytics dashboard
- Multi-tenant architecture with RLS

### 📱 **Multi-Platform Support**
- **iOS App**: Native SwiftUI with LiDAR support for measurement capture
- **Web App**: React-based commerce and try-on experience
- **API**: RESTful DMaaS endpoints for third-party integration

### 🔐 **Security & Compliance**
- JWT authentication with refresh token rotation
- Password breach checking (HaveIBeenPwned)
- Row-Level Security (RLS) in Supabase
- Audit logging for privileged actions
- PCI SAQ A compliance for payments

---

## Project Structure

```
fittwin-platform/
├── agents/                    # CrewAI multi-agent system
│   ├── crew/                  # Agent implementations (CEO, Architect, ML, DevOps, Reviewer)
│   ├── config/                # Agent configurations and LLM settings
│   ├── prompts/               # Prompt templates and assets
│   ├── tools/                 # Measurement, commerce, and rendering tools
│   └── client/                # API client for agent-backend communication
├── backend/                   # FastAPI backend application
│   └── app/
│       ├── core/              # Config, validation, auth, security
│       ├── routers/           # API endpoints (measurements, cart, orders, brands, etc.)
│       ├── schemas/           # Pydantic models and error envelopes
│       └── services/          # Business logic (fit rules, avatar, rendering, payments)
├── data/                      # Database and migrations
│   └── supabase/
│       ├── migrations/        # SQL migration files
│       └── README.md          # Supabase setup guide
├── docs/
│   ├── spec/                  # Technical specifications
│   ├── architecture/          # Architecture decision records (ADRs)
│   ├── api/                   # API documentation
│   └── runbooks/              # Operational guides
├── frontend/
│   └── web-app/               # React/Vite web application
│       └── client/
│           ├── public/        # Static assets
│           └── src/           # React components and pages
├── ios/                       # Native iOS application
│   └── FitTwinApp/
│       ├── FitTwinApp/        # SwiftUI app with LiDAR capture
│       └── FitTwinApp.xcodeproj
├── scripts/                   # Helper scripts (dev server, test runner, agents)
├── tests/
│   ├── backend/               # Backend/FastAPI tests
│   ├── agents/                # CrewAI tool tests with mocks
│   └── e2e/                   # End-to-end tests (Playwright)
├── workers/                   # Background job processors
│   ├── avatar-processor/      # Avatar mesh generation
│   ├── render-worker/         # Virtual try-on rendering
│   └── notification-worker/   # Email and push notifications
├── .github/
│   └── workflows/             # CI/CD pipelines
├── requirements.txt           # Python dependencies (production)
├── requirements-dev.txt       # Python dependencies (development)
├── package.json               # Node.js dependencies (web app)
└── README.md                  # This file
```

---

## Quick Start

### Prerequisites

- **Python 3.11+**
- **Node.js 18+** and **pnpm**
- **Supabase account** (free tier)
- **Stripe account** (test mode)
- **OpenAI API key** (for CrewAI agents)

### 1. Environment Setup

```bash
# Clone the repository
git clone https://github.com/rocketroz/fittwin-platform.git
cd fittwin-platform

# Create Python virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install Python dependencies
pip install -r requirements-dev.txt

# Install Node.js dependencies for web app
cd frontend/web-app/client
pnpm install
cd ../../..
```

### 2. Configuration

```bash
# Copy environment templates
cp backend/.env.example backend/.env
cp agents/.env.example agents/.env
cp frontend/web-app/client/.env.example frontend/web-app/client/.env
```

**Edit `backend/.env`:**
```env
# API Configuration
API_KEY=your-staging-secret-key

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...

# JWT
JWT_SECRET=your-random-secret-key
JWT_ALGORITHM=HS256
JWT_EXPIRATION_MINUTES=15
```

**Edit `agents/.env`:**
```env
# OpenAI for CrewAI
OPENAI_API_KEY=sk-...
AGENT_MODEL=gpt-4o-mini

# Backend API
BACKEND_API_URL=http://localhost:8000
BACKEND_API_KEY=your-staging-secret-key
```

### 3. Database Setup

```bash
# Install Supabase CLI (if not already installed)
brew install supabase/tap/supabase  # macOS
# or: npm install -g supabase

# Link to your Supabase project
supabase link --project-ref your-project-ref

# Run migrations
supabase db push

# Or manually run SQL files
psql $DATABASE_URL < data/supabase/migrations/001_init_schema.sql
psql $DATABASE_URL < data/supabase/migrations/002_measurement_provenance.sql
psql $DATABASE_URL < data/supabase/migrations/003_commerce_tables.sql
```

### 4. Run the Backend

```bash
# From project root
bash scripts/dev_server.sh

# Or manually
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

**Swagger UI:** http://localhost:8000/docs

### 5. Run the Web App

```bash
cd frontend/web-app/client
pnpm dev
```

**Web App:** http://localhost:5173

### 6. Run CrewAI Agents

```bash
# From project root
source .venv/bin/activate
python agents/crew/measurement_crew.py
```

---

## API Endpoints

All endpoints require an `X-API-Key` header (default: `staging-secret-key`).

### **Measurements (DMaaS)**

**Validate Measurements**
```bash
POST /measurements/validate
Content-Type: application/json
X-API-Key: staging-secret-key

{
  "waist_natural": 32,
  "hip_low": 40,
  "unit": "in",
  "session_id": "demo-123"
}
```

**Recommend Sizes**
```bash
POST /measurements/recommend
Content-Type: application/json
X-API-Key: staging-secret-key

{
  "waist_natural_cm": 81.28,
  "hip_low_cm": 101.6,
  "chest_cm": 101.6,
  "model_version": "v1.0-mediapipe"
}
```

### **Authentication**

```bash
POST /auth/signup       # Create user account
POST /auth/login        # Issue JWT tokens
POST /auth/refresh      # Rotate access token
POST /auth/logout       # Revoke refresh token
```

### **Cart & Checkout**

```bash
GET  /cart              # Get current cart
POST /cart/items        # Add item to cart
PUT  /cart/items/{id}   # Update cart item
DELETE /cart/items/{id} # Remove cart item
POST /checkout          # Complete checkout
```

### **Orders**

```bash
GET  /orders            # List user orders
GET  /orders/{id}       # Get order details
POST /orders/{id}/cancel # Cancel order
```

### **Brands (B2B)**

```bash
POST /brands            # Create brand
GET  /brands/{id}       # Get brand details
POST /brands/{id}/catalog # Upload catalog CSV
GET  /brands/{id}/analytics # Brand performance metrics
```

### **Referrals**

```bash
POST /referrals         # Create referral link
GET  /referrals/{rid}   # Get referral details
GET  /referrals/{rid}/events # Referral attribution events
```

---

## Testing

```bash
# Run all tests
bash scripts/test_all.sh

# Backend tests only
pytest tests/backend/ -v

# Agent tests only
pytest tests/agents/ -v

# E2E tests
cd tests/e2e
npx playwright test
```

---

## Deployment

### **Backend (FastAPI)**

**Option 1: Railway**
```bash
railway login
railway init
railway up
```

**Option 2: Fly.io**
```bash
fly launch
fly deploy
```

**Option 3: Render**
- Connect GitHub repository
- Set environment variables
- Deploy as Web Service

### **Web App (React)**

**Option 1: Vercel**
```bash
cd frontend/web-app/client
vercel
```

**Option 2: Netlify**
```bash
cd frontend/web-app/client
netlify deploy
```

### **iOS App**

```bash
cd ios/FitTwinApp
# Open in Xcode
open FitTwinApp.xcodeproj

# Build and deploy to TestFlight
# (Requires Apple Developer account)
```

---

## Architecture

### **Technology Stack**

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Measurement Capture** | Native iOS (SwiftUI) + LiDAR | Superior accuracy, native capabilities |
| **Measurement Processing** | Python + MediaPipe | Cost-effective, AI-friendly |
| **Backend** | FastAPI (Python) | Rapid development, automatic OpenAPI docs |
| **Database** | Supabase (PostgreSQL) | Production-ready, RLS, cost-effective |
| **AI Agents** | CrewAI (Python) | Development acceleration, autonomous workflows |
| **Web Frontend** | React + Vite | Modern, fast, component-rich |
| **Queue/Jobs** | BullMQ or Celery | Rendering, avatar generation, notifications |
| **Payment** | Stripe | Industry standard, tokenization support |
| **CDN/Storage** | Supabase Storage | Avatars, renders, photos |
| **Analytics** | Custom + PostHog/Mixpanel | Event tracking, user behavior |

### **Design Principles**

1. **AI-First Development**: Use CrewAI agents to accelerate feature development
2. **Cost Consciousness**: Prioritize free tiers and open-source solutions
3. **Security by Default**: RLS, JWT, password breach checking, audit logs
4. **Measurement Provenance**: Track full pipeline from photos to recommendations
5. **Dual-Platform Strategy**: Native iOS for capture, web for commerce
6. **DMaaS Business Model**: API-first design for B2B integration

---

## Development Roadmap

### **Phase 1: Foundation (Completed)** ✅
- [x] Repository merge and structure
- [x] Core measurement API (validate, recommend)
- [x] CrewAI agent system
- [x] iOS capture flow
- [x] Web app prototype
- [x] Supabase integration

### **Phase 2: Commerce (4-6 weeks)** 🚧
- [ ] Cart and checkout implementation
- [ ] User authentication (JWT)
- [ ] Payment integration (Stripe)
- [ ] Order management and lifecycle
- [ ] Address and payment method management

### **Phase 3: Virtual Try-On (6-8 weeks)** 📋
- [ ] Avatar generation pipeline
- [ ] Rendering worker service
- [ ] Fit zone visualization
- [ ] Alternative size recommendations
- [ ] iOS-to-web handoff

### **Phase 4: Brand Portal (4-6 weeks)** 📋
- [ ] Brand onboarding workflow
- [ ] Catalog management (CSV/API)
- [ ] Size chart configuration
- [ ] Brand analytics dashboard
- [ ] Multi-tenant RLS policies

### **Phase 5: Growth & Analytics (3-4 weeks)** 📋
- [ ] Referral system implementation
- [ ] Comprehensive event tracking
- [ ] Audit logging
- [ ] Admin dashboard
- [ ] Performance monitoring

### **Phase 6: Polish & Scale (Ongoing)** 📋
- [ ] Expand test coverage (>80%)
- [ ] Performance optimization (<2s API)
- [ ] Security audit
- [ ] Complete API documentation
- [ ] Production deployment

---

## Contributing

This is a private repository. For questions or contributions, contact Laura Tornga (@rocketroz).

### **Development Guidelines**

1. **Branch Naming**: `feature/`, `bugfix/`, `hotfix/`
2. **Commit Messages**: Use conventional commits (e.g., `feat:`, `fix:`, `docs:`)
3. **Code Style**: Follow PEP 8 (Python), Airbnb (JavaScript)
4. **Testing**: Write tests for all new features
5. **Documentation**: Update docs for API changes

---

## License

Proprietary - All Rights Reserved

---

## Support

For technical support or business inquiries:
- **Email**: support@fittwin.com
- **GitHub Issues**: [fittwin-platform/issues](https://github.com/rocketroz/fittwin-platform/issues)

---

## Acknowledgments

This project merges the best features from:
- **fittwindev/fittwin**: Commerce infrastructure, virtual try-on, brand portal
- **rocketroz/fitwin-crewai**: AI agents, MediaPipe integration, DMaaS model

Special thanks to the Manus AI team for development assistance.

---

**Built with ❤️ by Laura Tornga (@rocketroz)**
