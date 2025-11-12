# Supabase Backend Setup Guide

This guide walks you through setting up the Supabase backend for the FitTwin iOS app. The backend stores body measurements in the cloud, enabling cross-device sync and measurement history.

## Table of Contents

1. [Overview](#overview)
2. [Create Supabase Project](#create-supabase-project)
3. [Database Setup](#database-setup)
4. [Configure iOS App](#configure-ios-app)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Overview

**What is Supabase?**

Supabase is an open-source Firebase alternative that provides:
- PostgreSQL database
- Authentication (email, OAuth, anonymous)
- File storage
- Real-time subscriptions
- Auto-generated REST and GraphQL APIs

**What We're Building:**

The FitTwin iOS app will:
1. Authenticate users (anonymous auth for testing, email/OAuth for production)
2. Upload body measurements after each scan
3. Fetch measurement history
4. Optionally upload front/side photos to cloud storage

**Time Required:** 15-20 minutes

---

## Create Supabase Project

### Step 1: Sign Up for Supabase

1. Go to [https://supabase.com](https://supabase.com)
2. Click **"Start your project"**
3. Sign up with GitHub, Google, or email
4. Verify your email if required

### Step 2: Create a New Project

1. Click **"New Project"**
2. Fill in project details:
   - **Name:** `fittwin` (or any name you prefer)
   - **Database Password:** Generate a strong password (save this!)
   - **Region:** Choose closest to your location (e.g., `us-west-1`)
   - **Pricing Plan:** Free tier is sufficient for testing
3. Click **"Create new project"**
4. Wait 2-3 minutes for provisioning

### Step 3: Get API Credentials

1. Once the project is ready, go to **Settings** (gear icon in sidebar)
2. Click **API** in the left menu
3. You'll see two important values:
   - **Project URL:** `https://xxxxxxxxxxxxx.supabase.co`
   - **anon public key:** `eyJhbGc...` (long JWT token)
4. **Keep this tab open** - you'll need these values later

---

## Database Setup

### Step 1: Run Database Schema

1. In your Supabase dashboard, click **SQL Editor** in the left sidebar
2. Click **"New query"**
3. Open the file `supabase_schema.sql` (included in this project)
4. Copy the entire contents and paste into the SQL Editor
5. Click **"Run"** (or press `Cmd+Enter`)
6. You should see: `Success. No rows returned`

**What This Does:**
- Creates `measurements` table with 20+ body measurement fields
- Sets up Row Level Security (RLS) policies
- Creates storage bucket for measurement images
- Adds indexes for fast queries
- Creates triggers for automatic timestamps

### Step 2: Verify Tables

1. Click **Table Editor** in the left sidebar
2. You should see a new table: `measurements`
3. Click on it to see the columns:
   - `id` (UUID, primary key)
   - `user_id` (UUID, foreign key to auth.users)
   - `height_cm`, `shoulder_width`, `chest_circumference`, etc.
   - `created_at`, `updated_at`

### Step 3: Enable Anonymous Authentication (Optional)

For testing without requiring email/password:

1. Go to **Authentication** → **Providers**
2. Scroll to **Anonymous Sign-Ins**
3. Toggle **"Enable anonymous sign-ins"** to ON
4. Click **Save**

**Note:** For production, use email/password or OAuth providers instead.

---

## Configure iOS App

### Step 1: Install Supabase SDK

The Podfile already includes Supabase:

```ruby
pod 'Supabase', '~> 2.0'
```

Run in Terminal:

```bash
cd /path/to/fittwin-unified/ios-clean
pod install
```

### Step 2: Add Environment Variables

You have two options:

#### Option A: Xcode Scheme Environment Variables (Recommended for Development)

1. Open `FitTwin.xcworkspace` in Xcode
2. Click **Product** → **Scheme** → **Edit Scheme...**
3. Select **Run** in the left sidebar
4. Click **Arguments** tab
5. Under **Environment Variables**, click **+** twice
6. Add:
   - **Name:** `SUPABASE_URL`, **Value:** `https://xxxxxxxxxxxxx.supabase.co`
   - **Name:** `SUPABASE_ANON_KEY`, **Value:** `eyJhbGc...` (your anon key)
7. Click **Close**

#### Option B: Info.plist (For Production Builds)

1. Open `FitTwin/Info.plist`
2. Add two new keys:
   ```xml
   <key>SUPABASE_URL</key>
   <string>https://xxxxxxxxxxxxx.supabase.co</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>eyJhbGc...</string>
   ```
3. Update `SupabaseService.swift` to read from Info.plist:
   ```swift
   init() {
       guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
             let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
           fatalError("Missing Supabase credentials in Info.plist")
       }
       self.supabaseURL = url
       self.supabaseKey = key
       setupClient()
   }
   ```

**⚠️ Security Note:** Never commit API keys to public repositories. Use environment variables or secure configuration management.

### Step 3: Initialize SupabaseService

The `SupabaseService` is already created. You need to inject it into your app:

1. Open `FitTwinApp.swift` (or your main app file)
2. Add the service as a `@StateObject`:

```swift
import SwiftUI

@main
struct FitTwinApp: App {
    @StateObject private var supabaseService = SupabaseService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabaseService)
        }
    }
}
```

### Step 4: Update ProcessingView

The `ProcessingView` is already updated to:
- Accept `measurementData` parameter
- Use `@EnvironmentObject var supabaseService: SupabaseService`
- Automatically upload measurements when processing completes
- Show upload status in the UI

Make sure to pass `measurementData` when navigating to `ProcessingView`:

```swift
// In your capture flow
NavigationLink(destination: ProcessingView(
    progress: processingProgress,
    measurementData: capturedMeasurements
)) {
    Text("Continue")
}
```

---

## Testing

### Step 1: Build and Run

1. Connect your iPhone via USB-C
2. Select your device in Xcode (top toolbar)
3. Click **Run** (▶️) or press `Cmd+R`
4. Wait for build to complete

### Step 2: Capture Measurements

1. Complete the onboarding flow
2. Enter your height
3. Capture front-facing photo with pose detection
4. Wait for processing to complete
5. Watch for the **"Syncing to cloud"** status

### Step 3: Verify in Supabase Dashboard

1. Go to your Supabase dashboard
2. Click **Table Editor** → **measurements**
3. You should see a new row with:
   - Auto-generated `id`
   - `user_id` (from anonymous auth)
   - All your body measurements
   - `created_at` timestamp
   - Device metadata

### Step 4: Check Xcode Console

Look for log messages:

```
✅ Measurement uploaded successfully: 123e4567-e89b-12d3-a456-426614174000
```

Or if it failed:

```
❌ Upload failed: [error message]
```

---

## Troubleshooting

### Issue: "Supabase client not initialized"

**Cause:** Missing or invalid environment variables

**Fix:**
1. Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set correctly
2. Check for typos in the URL (must start with `https://`)
3. Ensure anon key is the full JWT token (starts with `eyJhbGc...`)

### Issue: "User not authenticated"

**Cause:** Anonymous auth not enabled or failed

**Fix:**
1. Enable anonymous sign-ins in Supabase dashboard (see [Step 3](#step-3-enable-anonymous-authentication-optional))
2. Check Xcode console for auth errors
3. Try signing in manually:
   ```swift
   Task {
       try await supabaseService.signInAnonymously()
   }
   ```

### Issue: "Failed to upload measurement"

**Cause:** RLS policies blocking insert, or network error

**Fix:**
1. Verify RLS policies are created (run `supabase_schema.sql` again)
2. Check internet connection
3. Look at detailed error in Xcode console
4. Test with Supabase API directly:
   ```bash
   curl -X POST 'https://xxxxxxxxxxxxx.supabase.co/rest/v1/measurements' \
     -H "apikey: YOUR_ANON_KEY" \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -H "Content-Type: application/json" \
     -d '{"user_id":"test","height_cm":175,"shoulder_width":45,...}'
   ```

### Issue: "Pod install fails"

**Cause:** CocoaPods cache or version issues

**Fix:**
```bash
pod deintegrate
pod cache clean --all
pod install
```

### Issue: "Measurements table not found"

**Cause:** Schema SQL didn't run successfully

**Fix:**
1. Go to SQL Editor in Supabase
2. Run this query to check:
   ```sql
   SELECT * FROM information_schema.tables WHERE table_name = 'measurements';
   ```
3. If empty, re-run `supabase_schema.sql`

---

## Next Steps

### Production Checklist

Before deploying to production:

- [ ] Replace anonymous auth with email/password or OAuth
- [ ] Add user profile table (name, email, preferences)
- [ ] Implement measurement history view in iOS app
- [ ] Add data export functionality
- [ ] Set up Supabase backups
- [ ] Configure custom domain (optional)
- [ ] Add analytics/monitoring
- [ ] Implement rate limiting
- [ ] Add measurement comparison features
- [ ] Create admin dashboard for support

### Advanced Features

Consider adding:

1. **Real-time Sync:** Use Supabase Realtime to sync measurements across devices instantly
2. **Image Storage:** Upload front/side photos to `measurement-images` bucket
3. **Measurement History:** Fetch and display past measurements with charts
4. **Size Recommendations:** Integrate with clothing brand APIs
5. **Social Sharing:** Allow users to share measurements with retailers
6. **Measurement Comparison:** Show changes over time
7. **Export to CSV/PDF:** Generate reports

---

## Support

**Supabase Documentation:**
- [Getting Started](https://supabase.com/docs)
- [iOS Client Library](https://github.com/supabase-community/supabase-swift)
- [Authentication](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

**FitTwin Support:**
- GitHub Issues: [Create an issue](https://github.com/rocketroz/fittwin-unified/issues)
- Email: support@fittwin.com (if applicable)

---

## Summary

You've successfully:
- ✅ Created a Supabase project
- ✅ Set up the database schema
- ✅ Configured the iOS app with Supabase SDK
- ✅ Enabled automatic measurement uploads
- ✅ Tested end-to-end functionality

Your FitTwin app now has a fully functional cloud backend! 🎉

Measurements are automatically synced to Supabase after each scan, enabling:
- Cross-device access
- Measurement history
- Data backup
- Future integrations with clothing retailers

**Next:** Test on your iPhone and verify measurements appear in the Supabase dashboard.
