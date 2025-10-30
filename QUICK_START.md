# FitTwin Unified Platform - Quick Start Guide

## 🚀 Get Started in 15 Minutes

This guide will help you set up your development environment and start building.

---

## Step 1: Apply Database Migrations (5 minutes)

### Via Supabase Dashboard (Easiest)

1. **Go to SQL Editor**
   - Open https://supabase.com/dashboard/project/omufrexozpveazrjdeqe/sql/new
   
2. **Run each migration in order:**

   **Migration 1: Initial Schema**
   ```sql
   -- Copy and paste from: data/supabase/migrations/init_schema.sql
   ```

   **Migration 2: Measurement Provenance**
   ```sql
   -- Copy and paste from: data/supabase/migrations/002_measurement_provenance.sql
   -- Skip lines 1-49 (duplicate definitions), start from line 50
   ```

   **Migration 3: Commerce Tables**
   ```sql
   -- Copy and paste from: data/supabase/migrations/003_commerce_tables.sql
   ```

   **Migration 4: Brand Tables**
   ```sql
   -- Copy and paste from: data/supabase/migrations/004_brand_tables.sql
   ```

   **Migration 5: Referral Tables**
   ```sql
   -- Copy and paste from: data/supabase/migrations/005_referral_tables.sql
   ```

   **Migration 6: Auth Enhancements**
   ```sql
   -- Copy and paste from: data/supabase/migrations/006_auth_enhancements.sql
   ```

   **Migration 7: Referrals and Brand Admins**
   ```sql
   -- Copy and paste from: data/supabase/migrations/007_referrals_and_brand_admins.sql
   ```

3. **Verify tables were created**
   - Go to Table Editor: https://supabase.com/dashboard/project/omufrexozpveazrjdeqe/editor
   - You should see all the tables listed

---

## Step 2: Configure Environment (3 minutes)

1. **Clone the repository** (if you haven't already)
   ```bash
   git clone https://github.com/rocketroz/fittwin-unified.git
   cd fittwin-unified
   ```

2. **Copy environment template**
   ```bash
   cp .env.example .env
   ```

3. **Edit `.env` file** with your credentials:
   ```bash
   nano .env  # or use your preferred editor
   ```

   **Required values:**
   ```env
   # Supabase
   SUPABASE_URL=https://omufrexozpveazrjdeqe.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9tdWZyZXhvenB2ZWF6cmpkZXFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NTIzMTAsImV4cCI6MjA0NjAyODMxMH0.8y2Jgc3H1Oz6NHhvR9hXr-zy2k2JxJ1c1Egt0nfE
   SUPABASE_SERVICE_ROLE_KEY=<GET_FROM_DASHBOARD>
   
   # JWT Secret (generate with: openssl rand -hex 32)
   JWT_SECRET=<GENERATE_THIS>
   
   # API Key (generate with: openssl rand -hex 32)
   API_KEY=<GENERATE_THIS>
   ```

4. **Generate secrets**
   ```bash
   # Generate JWT secret
   openssl rand -hex 32
   
   # Generate API key
   openssl rand -hex 32
   ```
   
   Copy the output and paste into your `.env` file.

5. **Get Service Role Key**
   - Go to https://supabase.com/dashboard/project/omufrexozpveazrjdeqe/settings/api-keys
   - Click "Reveal" next to `service_role`
   - Copy the key and paste into `.env`

---

## Step 3: Start the Backend (2 minutes)

1. **Install Python dependencies**
   ```bash
   cd backend
   pip3 install -r ../requirements.txt
   ```

2. **Start the development server**
   ```bash
   cd ..
   ./scripts/dev_server.sh
   ```

3. **Verify it's running**
   - Open http://localhost:8000/docs
   - You should see the API documentation

---

## Step 4: Test the API (5 minutes)

### Test 1: Health Check
```bash
curl http://localhost:8000/api/v1/health
```

Expected response:
```json
{"status": "healthy"}
```

### Test 2: Create a User
Go to http://localhost:8000/docs and try:

1. **POST /api/v1/auth/signup**
   ```json
   {
     "email": "test@example.com",
     "password": "TestPassword123!",
     "name": "Test User"
   }
   ```

2. **POST /api/v1/auth/signin**
   ```json
   {
     "email": "test@example.com",
     "password": "TestPassword123!"
   }
   ```

3. Copy the `access_token` from the response

4. **GET /api/v1/auth/me**
   - Click "Authorize" button
   - Paste your access token
   - Click "Authorize"
   - Try the endpoint

---

## Step 5: Start Building! 🎉

You're now ready to:

1. **Build the frontend UI** - See `docs/IMPLEMENTATION_ROADMAP.md` for Phase 2
2. **Test the mobile app** - See `mobile/README.md`
3. **Run the CrewAI agents** - See `agents/README.md`

---

## 📚 Next Steps

### Phase 2: Build Frontend UI

**Cart Page** (`web-app/src/pages/Cart.tsx`)
- Display cart items
- Update quantities
- Remove items
- Show totals

**Checkout Page** (`web-app/src/pages/Checkout.tsx`)
- Collect shipping address
- Integrate Stripe payment
- Create order

**Orders Page** (`web-app/src/pages/Orders.tsx`)
- List user orders
- Show order details
- Track shipments

### Phase 3: Mobile Integration

**Connect iOS App to Backend**
- Update API endpoints in `mobile/app/services/*.ts`
- Test LiDAR capture → measurement API flow
- Implement cart and checkout in mobile app

### Phase 4: Deploy to Production

**Backend Deployment** (Railway, Fly.io, or Render)
```bash
# Example for Railway
railway init
railway up
```

**Database** (Already on Supabase ✅)

**Frontend** (Vercel or Netlify)
```bash
cd web-app
vercel deploy
```

---

## 🆘 Troubleshooting

### Issue: "Module not found" errors
**Solution:** Make sure you're in the correct directory and have installed dependencies:
```bash
cd /path/to/fittwin-unified
pip3 install -r requirements.txt
```

### Issue: "Connection refused" to Supabase
**Solution:** Check your `.env` file has the correct `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`

### Issue: "Table does not exist"
**Solution:** Make sure you've run all the database migrations in Step 1

### Issue: "Invalid JWT token"
**Solution:** Make sure you've generated a `JWT_SECRET` and added it to `.env`

---

## 📖 Documentation

- **Full Setup Guide:** `SUPABASE_SETUP_GUIDE.md`
- **Implementation Roadmap:** `docs/IMPLEMENTATION_ROADMAP.md`
- **Architecture:** `docs/ARCHITECTURE.md`
- **Production-Ready Summary:** `PRODUCTION_READY_SUMMARY.md`

---

## 🎯 Success Checklist

- [ ] Database migrations applied
- [ ] `.env` file configured
- [ ] Backend server running on http://localhost:8000
- [ ] API docs accessible at http://localhost:8000/docs
- [ ] Test user created successfully
- [ ] Authentication working (signup/signin/me)

**Once all checked, you're ready to build Phase 2!** 🚀
