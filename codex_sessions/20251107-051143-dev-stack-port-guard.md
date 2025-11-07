# dev stack port guard

- Timestamp: 2025-11-07 05:11:43 PST
- Branch: feature/web-hotfix
- Commit: 4b59c156
- Tags: devstack, backend

## Notes
dev-stack.mjs now kills existing processes on ports 3000/3001/3100 before launch.
Need Postgres running on 54322 to finish scripts/run_all_db_tests.sh Pass 2.

## Git Status
```text
M scripts/dev-stack.mjs
 M services/python/measurement/scripts/test_all.sh
?? agents/
?? screenshots_local/
?? tmp-postgres/
```

## Git Diff
```diff
diff --git a/scripts/dev-stack.mjs b/scripts/dev-stack.mjs
index 0addea6d..2141291d 100755
--- a/scripts/dev-stack.mjs
+++ b/scripts/dev-stack.mjs
@@ -1,5 +1,5 @@
 #!/usr/bin/env node
-import { spawn } from 'node:child_process';
+import { spawn, spawnSync } from 'node:child_process';
 import path from 'node:path';
 import process from 'node:process';
 import url from 'node:url';
@@ -8,13 +8,17 @@ const dbMode = (process.env.DATABASE_MODE ?? 'local').toLowerCase();
 const scriptDir = path.dirname(url.fileURLToPath(import.meta.url));
 const rootDir = path.resolve(scriptDir, '..');
 
+const backendPort = process.env.BACKEND_PORT ?? '3000';
+const shopperPort = process.env.SHOPPER_PORT ?? '3001';
+const brandPort = process.env.BRAND_PORT ?? '3100';
+
 const services = [
   {
     label: 'backend',
     command: 'npx',
     args: ['nodemon', '--watch', 'backend/src', '--ext', 'ts,js,json', '--exec', 'npm run backend:dev'],
     env: {
-      PORT: process.env.BACKEND_PORT ?? '3000',
+      PORT: backendPort,
       HOST: '0.0.0.0',
       DATABASE_MODE: process.env.DATABASE_MODE ?? 'local',
     },
@@ -24,11 +28,11 @@ const services = [
     command: 'npm',
     args: ['run', 'dev', '--workspace', 'frontend/apps/shopper'],
     env: {
-      PORT: process.env.SHOPPER_PORT ?? '3001',
-      BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
-      NEXT_PUBLIC_BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
+      PORT: shopperPort,
+      BACKEND_BASE_URL: `http://localhost:${backendPort}`,
+      NEXT_PUBLIC_BACKEND_BASE_URL: `http://localhost:${backendPort}`,
       NEXT_PUBLIC_API_PROXY_BASE: process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend',
-      E2E_SHOPPER_URL: `http://localhost:${process.env.SHOPPER_PORT ?? '3001'}`,
+      E2E_SHOPPER_URL: `http://localhost:${shopperPort}`,
     },
   },
   {
@@ -36,15 +40,41 @@ const services = [
     command: 'npm',
     args: ['run', 'dev', '--workspace', 'frontend/apps/brand-portal'],
     env: {
-      PORT: process.env.BRAND_PORT ?? '3100',
-      BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
-      NEXT_PUBLIC_BACKEND_BASE_URL: `http://localhost:${process.env.BACKEND_PORT ?? '3000'}`,
+      PORT: brandPort,
+      BACKEND_BASE_URL: `http://localhost:${backendPort}`,
+      NEXT_PUBLIC_BACKEND_BASE_URL: `http://localhost:${backendPort}`,
       NEXT_PUBLIC_API_PROXY_BASE: process.env.NEXT_PUBLIC_API_PROXY_BASE ?? '/api/backend',
-      E2E_BRAND_URL: `http://localhost:${process.env.BRAND_PORT ?? '3100'}`,
+      E2E_BRAND_URL: `http://localhost:${brandPort}`,
     },
   },
 ];
 
+function ensurePortFree(port, label) {
+  const lookup = spawnSync('lsof', ['-ti', `tcp:${port}`], { encoding: 'utf8' });
+  if (lookup.status !== 0 || !lookup.stdout.trim()) {
+    return;
+  }
+  console.log(`[dev-stack] ${label} port ${port} already in use; terminating existing processes.`);
+  for (const pid of lookup.stdout.trim().split('\n')) {
+    if (!pid) continue;
+    try {
+      process.kill(Number(pid), 'SIGTERM');
+    } catch {
+      // ignore; process may already be gone
+    }
+  }
+}
+
+const portGuards = [
+  { port: backendPort, label: 'backend' },
+  { port: shopperPort, label: 'shopper' },
+  { port: brandPort, label: 'brand' },
+];
+
+for (const guard of portGuards) {
+  ensurePortFree(guard.port, guard.label);
+}
+
 const children = [];
 let shuttingDown = false;
 
diff --git a/services/python/measurement/scripts/test_all.sh b/services/python/measurement/scripts/test_all.sh
index 8ae50529..bdab8d6f 100755
--- a/services/python/measurement/scripts/test_all.sh
+++ b/services/python/measurement/scripts/test_all.sh
@@ -3,6 +3,10 @@
 
 set -e
 
+SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
+SERVICE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
+REPO_ROOT="$(cd "$SERVICE_ROOT/../../.." && pwd)"
+
 echo "🧪 Running FitTwin Platform Tests..."
 
 # Activate virtual environment if available
@@ -27,7 +31,7 @@ if [ -f ".env.test" ]; then
 fi
 
 # Set PYTHONPATH
-export PYTHONPATH="${PYTHONPATH}:$(pwd):$(pwd)/backend"
+export PYTHONPATH="${PYTHONPATH}:${SERVICE_ROOT}:${SERVICE_ROOT}/backend:${REPO_ROOT}:${REPO_ROOT}/agents"
 
 # Run backend tests
 echo ""
```
