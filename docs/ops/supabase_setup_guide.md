# Supabase Setup Guide for FitTwin Unified Platform

## ✅ Project Information

**Project Name:** fittwin-backend  
**Organization:** rocketroz's Org  
**Region:** AWS us-east-2  
**Plan:** Free  

**Project URL:** `https://omufrexozpveazrjdeqe.supabase.co`

---

## 🔑 API Keys

### Anon (Public) Key
This key is safe to use in client-side code (mobile app, web app).

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9tdWZyZXhvenB2ZWF6cmpkZXFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NTIzMTAsImV4cCI6MjA0NjAyODMxMH0.8y2Jgc3H1Oz6NHhvR9hXr-zy2k2JxJ1c1Egt0nfE
```

### Service Role (Secret) Key
**⚠️ IMPORTANT:** This key has admin privileges. **NEVER** expose it in client-side code or commit it to public repositories. Only use it in your backend server.

**You need to reveal this key in the Supabase dashboard:**
1. Go to Project Settings → API Keys
2. Click "Reveal" next to service_role key
3. Copy the key and add it to your `.env` file

---

## 📝 Environment Configuration

### Step 1: Update Your `.env` File

Navigate to your `fittwin-unified` repository and update the `.env` file:

```bash
cd /path/to/fittwin-unified
cp .env.example .env
nano .env  # or use your preferred editor
```

### Step 2: Add Supabase Credentials

Update these values in your `.env` file:

```env
# Supabase Configuration
SUPABASE_URL=https://omufrexozpveazrjdeqe.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9tdWZyZXhvenB2ZWF6cmpkZXFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA0NTIzMTAsImV4cCI6MjA0NjAyODMxMH0.8y2Jgc3H1Oz6NHhvR9hXr-zy2k2JxJ1c1Egt0nfE
SUPABASE_SERVICE_ROLE_KEY=<REVEAL_IN_DASHBOARD_AND_PASTE_HERE>

# JWT Configuration
JWT_SECRET=<GENERATE_WITH: openssl rand -hex 32>
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=15
JWT_REFRESH_TOKEN_EXPIRE_DAYS=30

# Stripe Configuration (not yet configured)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# OpenAI Configuration (for CrewAI agents)
OPENAI_API_KEY=<YOUR_OPENAI_API_KEY>

# Application Configuration
API_KEY=<GENERATE_WITH: openssl rand -hex 32>
ENVIRONMENT=development
DATABASE_MODE=supa
DATABASE_URL=postgres://<service-role-user>:<service-role-key>@omufrexozpveazrjdeqe.supabase.co:5432/postgres
```

### Step 3: Generate Required Secrets

Run these commands to generate secure secrets:

```bash
# Generate JWT secret
openssl rand -hex 32

# Generate API key
openssl rand -hex 32
```

Copy the output and paste into your `.env` file.

---

## 🗄️ Database Setup

### Step 1: Install Supabase CLI (Optional but Recommended)

```bash
# macOS
brew install supabase/tap/supabase

# Linux
curl -fsSL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
sudo mv supabase /usr/local/bin/

# Windows (PowerShell)
scoop install supabase
```

### Step 2: Link Your Project

```bash
cd /path/to/fittwin-unified
supabase link --project-ref omufrexozpveazrjdeqe
```

When prompted, enter your database password (you set this when creating the project).

### Step 3: Run Database Migrations

You have two options:

#### Option A: Using Supabase CLI (Recommended)

```bash
cd /path/to/fittwin-unified
supabase db push
```

This will automatically run all migrations in `data/supabase/migrations/` in order.

#### Option B: Manually via SQL Editor

1. Go to Supabase Dashboard → SQL Editor
2. Run each migration file in order:
   - `001_initial_schema.sql`
   - `002_measurements_tables.sql`
   - `003_commerce_tables.sql`
   - `004_brand_tables.sql`
   - `005_referral_tables.sql`
   - `006_auth_enhancements.sql`
   - `007_referrals_and_brand_admins.sql`

---

## ✅ Verify Setup

### Step 1: Check Database Tables

Go to Supabase Dashboard → Table Editor and verify these tables exist:

**Core Tables:**
- users
- profiles
- measurements
- avatars

**Commerce Tables:**
- carts
- cart_items
- orders
- order_items

**Brand Tables:**
- brands
- products
- product_variants
- brand_admins

**Referral Tables:**
- referrals
- referral_events
- referral_rewards

**Auth Tables:**
- refresh_tokens

### Step 2: Test API Connection

```bash
cd /path/to/fittwin-unified/backend
pip3 install -r requirements.txt
python3 -c "
from supabase import create_client
import os
from dotenv import load_dotenv

load_dotenv()
supabase = create_client(
    os.getenv('SUPABASE_URL'),
    os.getenv('SUPABASE_SERVICE_ROLE_KEY')
)
print('✅ Supabase connection successful!')
print(f'Project URL: {os.getenv(\"SUPABASE_URL\")}')
"
```

If you see "✅ Supabase connection successful!", your setup is complete!

---

## 🚀 Start Development

### Step 1: Start the Backend Server

```bash
cd /path/to/fittwin-unified
./scripts/dev_server.sh
```

The API will be available at:
- **API:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs
- **OpenAPI Spec:** http://localhost:8000/openapi.json

### Step 2: Test the API

Open your browser and go to http://localhost:8000/docs to see the interactive API documentation.

Try these endpoints:
- `GET /api/v1/health` - Health check
- `POST /api/v1/auth/signup` - Create a test user
- `POST /api/v1/auth/signin` - Sign in

---

## 📊 Monitoring and Management

### Supabase Dashboard

Access your project dashboard at:
https://supabase.com/dashboard/project/omufrexozpveazrjdeqe

**Key Sections:**
- **Table Editor** - View and edit data
- **SQL Editor** - Run custom queries
- **Database** - Monitor performance
- **Authentication** - Manage users
- **Logs** - View API logs
- **Reports** - Usage statistics

### Database Connection String

If you need direct PostgreSQL access:

```
postgresql://postgres:[YOUR-PASSWORD]@db.omufrexozpveazrjdeqe.supabase.co:5432/postgres
```

Replace `[YOUR-PASSWORD]` with your database password.

---

## 🔒 Security Best Practices

1. **Never commit `.env` file** - It's already in `.gitignore`
2. **Use service_role key only in backend** - Never expose it to clients
3. **Enable Row Level Security (RLS)** - Already configured in migrations
4. **Rotate keys if compromised** - Can be done in Project Settings
5. **Monitor API usage** - Check Dashboard → Usage regularly

---

## 🆘 Troubleshooting

### Issue: "Invalid API key"
**Solution:** Make sure you've revealed and copied the service_role key correctly from the dashboard.

### Issue: "Connection refused"
**Solution:** Check that your Supabase project is not paused. Free tier projects pause after 7 days of inactivity.

### Issue: "Table does not exist"
**Solution:** Run the database migrations. See "Database Setup" section above.

### Issue: "RLS policy violation"
**Solution:** Make sure you're using the service_role key in the backend, not the anon key.

---

## 📚 Additional Resources

- **Supabase Documentation:** https://supabase.com/docs
- **Supabase Python Client:** https://github.com/supabase-community/supabase-py
- **FitTwin Platform Docs:** See `docs/` directory in repository
- **Implementation Roadmap:** See `docs/IMPLEMENTATION_ROADMAP.md`

---

## ✅ Next Steps

After completing this setup:

1. ✅ **Supabase configured** - Database and API keys ready
2. ⏭️ **Build frontend UI** - Cart and checkout interfaces
3. ⏭️ **Configure Stripe** - Payment processing
4. ⏭️ **Deploy to production** - Railway, Fly.io, or similar

**You're now ready to start building Phase 2 features!** 🎉
- **Remember:** the Nest dev launcher reads `DATABASE_MODE`. Set it to `supa` when targeting this project, or to `local` when working against a local Postgres clone. Example:
  ```bash
  export DATABASE_MODE=supa
  export DATABASE_URL="postgres://<service-role-user>:<service-role-key>@omufrexozpveazrjdeqe.supabase.co:5432/postgres"
  npm run dev:stack
  ```
