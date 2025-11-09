# FitTwin Platform

FitTwin is a monorepo that bundles the NestJS backend, Next.js shopper and brand portals, and NativeScript lab shells used for native demos. This README captures how we spin up the full stack locally and the tooling you need around it.

> **New:** CrewAI/Manus measurement assets, Supabase runbooks, and unified
> platform documentation now live under `services/`, `ai/`, `supabase/`, and
> `docs/`. Start with `docs/README.md` for an index of the imported materials,
> and use `services/python/measurement` as the FastAPI home while we port the
> logic into Nest modules.

Additional reference clients:
- Native React/Vite shopper flows (`frontend/reference/unified-web`)
- Manus capture web app (`frontend/reference/manus-web`)
- SwiftUI LiDAR capture prototype (`mobile/ios/FitTwinApp`)

## Prerequisites

### Core toolchain
- Node.js and npm (LTS release recommended).
- Repo dependencies installed once with `npm install`.

### NativeScript shells (optional but common)
- NativeScript CLI: `npm install -g nativescript`
- macOS: Xcode + CocoaPods (`sudo xcode-select --switch`, `sudo gem install cocoapods`)
- Java 17 JDK (Android Gradle plugin requires it):
  ```bash
  brew install --cask temurin17   # or install via Adoptium DMG
  export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
  ```
- Android SDK/NDK with `ANDROID_HOME`/`JAVA_HOME` set, required packages installed via `sdkmanager`, and `adb` on your `$PATH`.
  ```bash
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
  sdkmanager --install "platform-tools" "platforms;android-34" "build-tools;34.0.0" "system-images;android-34;google_apis;x86_64"
  sdkmanager --licenses
  ```

> Tip: `./scripts/lab-doctor.zsh` reports any missing SDKs, ports, or tools before you attempt a mobile run.

## Environment setup

From the repo root:

```bash
cp stack.env.example stack.env
export $(grep -v '^#' stack.env | xargs)
```

The sample file defines defaults for the backend (`3000`), shopper app (`3001`), brand portal (`3100`), AR lab flags, and the URLs used by the NativeScript shells. Adjust ports if they conflict, then re-export.

## Launch the full stack

Start the coordinated backend + web stack:

```bash
npm run dev:stack
# equivalent: node scripts/dev-stack.mjs
```

The script fans out to:
- Nest backend: `npm run start:dev --workspace backend`
- Shopper Next.js app: `npm run dev --workspace frontend/apps/shopper`
- Brand portal: `npm run dev --workspace frontend/apps/brand-portal`

Press `Ctrl+C` to stop all services together. Keep this running while you work with the web apps or NativeScript shells.

> The stack script now performs a preflight cleanup so you don’t inherit stray `next dev` or `ns run` processes. Tweak it via:
> - `DEV_STACK_PREFLIGHT=0` – skip the cleanup entirely.
> - `DEV_STACK_PORTS=3000,3001,…` / `DEV_STACK_KILL_PATTERNS="next dev,ns run"` – override what gets terminated.
> - `DEV_STACK_MANAGE_DB=off` – opt out of automatic Postgres bootstrapping. When `DATABASE_MODE=local`, the script will otherwise run `scripts/setup_postgres_test_db.sh` (using Docker) if `pg_isready` fails so the backend always has a live database.
> - Docker/psql are required for the automatic Postgres setup. If you don’t have Docker installed locally, set `START_DOCKER=0` (and run your own Postgres instance) to prevent the bootstrap from erroring out.
> - We keep `.npmrc` `workspaces=true` for lint/test fans out, so `dev-stack` sets `npm_config_workspaces=false` internally when launching the frontend apps; you don’t need to do anything extra.

Before running in `DATABASE_MODE=local`, execute `scripts/check_local_mode_prereqs.sh` (add `--install` to auto-install via Homebrew) to verify Node/npm versions, direnv, Docker Desktop, `libpq` CLIs, and the optional Postgres container are in place.

## Smoke tests

Once the stack is healthy:

```bash
npx playwright install           # first run only
PLAYWRIGHT_BROWSERS_READY=true npm run test:e2e
```

Override `E2E_SHOPPER_URL` / `E2E_BRAND_URL` if you changed ports in `stack.env`.

To exercise the full mixed stack (Node + Python + CrewAI), run:

```bash
npm run test:full
```

This script runs turborepo tests, then calls `services/python/measurement/scripts/test_all.sh` to exercise the FastAPI backend and CrewAI suites (honouring `.env.test`). If the Python virtualenv is missing (or packages are unavailable offline), the script exits gracefully with a warning.

## Database modes

The Nest backend now supports two Postgres targets:

- **Local** (default): set up a local Postgres instance, apply the SQL under `supabase/migrations/`, and run
  ```bash
  export DATABASE_MODE=local
  export DATABASE_URL=postgres://fit:fit@localhost:5432/fittwin
  npm run dev:stack
  ```
- **Supabase**: point at a hosted Supabase project with RLS enabled
  ```bash
  export DATABASE_MODE=supa
  export DATABASE_URL="postgres://<service-role-user>:<service-role-key>@<project>.supabase.co:5432/postgres"
  npm run dev:stack
  ```

`DATABASE_MODE` defaults to `local` if omitted; override TLS/SSL settings via standard TypeORM options when you introduce the shared `DatabaseModule`.

## NativeScript lab shells

Run these from the repo root after the web stack is live:

```bash
npm run ns:shopper:ios      # or ns:shopper:android
npm run ns:brand:ios        # or ns:brand:android
```

Both shells load the lab experiences via WebView (`NS_LAB_URL` and `NS_BRAND_URL` in `stack.env`). Update those variables or edit in-app to point at alternate endpoints.

> **Workspace note:** `.npmrc` sets `workspaces=true` *and* `include-workspace-root=true`. `npm run dev:stack` now calls the launcher directly, and the per-workspace `dev:stack` scripts are harmless no-ops, so you won’t see the `--no-workspaces` conflict anymore. If you need to run other root-only scripts manually, you can still scope them with `npm_config_workspaces=false npm run …` (or append `--workspaces=false`).
> **Docker note:** Docker bootstrap is **off by default** (`START_DOCKER` defaults to `0`). If you want the script to start a local container for you, export `START_DOCKER=1` first. When Docker isn’t available (or you leave the default of `0`), the script simply assumes you have Postgres running locally on `POSTGRES_PORT` (default `54322`) and logs a warning so you know the container step was skipped.
> **psql note:** Automatic migrations require the `psql` CLI. If it’s missing, the script skips the bootstrap entirely and logs a warning—make sure you’ve applied the schema yourself or install the PostgreSQL client (`brew install libpq && brew link --force libpq`) before re-running.

NativeScript launch helpers (`scripts/run-ns.sh`, `scripts/run-ns-android.zsh`) now mirror the web preflight:
- They kill lingering `ns run`, `xcodebuild`, Simulator, and adb processes plus the common lab ports before relaunching. Disable with `NS_PREFLIGHT=0`, or override the targets via `NS_KILL_PATTERNS` / `NS_KILL_PORTS`.
- HMR is on by default; set `NS_ENABLE_HMR=0` or pass `--no-hmr` to fall back to the old static reload cycle.
- The “TEST SUITES” button in the shell toggles a diagnostics panel fed by `NS_TEST_STATUS_URL`. Point this variable (or `TEST_STATUS_URL`) at an endpoint that returns a JSON object like:
  ```json
  {
    "updatedAt": "2025-11-07T07:45:00Z",
    "databaseMode": "local",
    "endpoints": {
      "devStack": "http://localhost:3000",
      "measurementApi": "http://localhost:8000/api",
      "cameraApi": "http://localhost:3100/camera"
    },
    "suites": [
      { "name": "backend:test:full", "status": "pass", "durationMs": 4100 },
      { "name": "playwright:e2e", "status": "fail", "details": "timeout on /measurements" }
    ]
  }
  ```
  The panel is off by default; tap the button to fetch and display the most recent data (raw JSON included for auditing). If the endpoint is omitted the button will show a configuration warning.
- Use `npm run test:status` to run the default suite list and produce `test-results/status.json`. This script automatically scopes npm workspaces, captures command durations, and records the `DATABASE_MODE`. Point your backend (or any static host) at that JSON file to expose the data via HTTP (see `/diagnostics/test-status` below).
- The collector now emits connectivity checks for the backend, measurement API, camera lab, database, and any extra endpoints defined via `TEST_STATUS_PING_ENDPOINTS` (comma-separated `label|url`). Set `TEST_STATUS_SKIP_DB_CHECK=1` if you don’t have `pg_isready` installed locally.

### Diagnostics endpoint

The Nest backend now exposes `GET /diagnostics/test-status`, which reads `test-results/status.json` (or any path set via `TEST_STATUS_FILE`). Host this endpoint wherever your NativeScript shell can reach it, and set `NS_TEST_STATUS_URL` to that URL. The response mirrors the JSON format shown above, so the “TEST SUITES” button can display live data pulled from your actual CLI runs.

### NativeScript dependencies

These NativeScript projects are not part of the root npm workspaces. Run an install the first time (and whenever dependencies change):

```bash
cd frontend/nativescript/shopper-lab && npm install
cd frontend/nativescript/brand-lab && npm install
cd frontend/nativescript/shopper-lab && npm install --save-dev @nativescript/webpack@^5 @nativescript/types
cd frontend/nativescript/brand-lab && npm install --save-dev @nativescript/webpack@^5 @nativescript/types
```

If you encounter:

```
Cannot find module '@nativescript/webpack/lib/before-checkForChanges.js'
```

it means the dependencies above are missing. Install them, then retry the `npm run ns:*` command. When the CLI warns that `platforms/android` looks invalid, run:

```bash
cd frontend/nativescript/shopper-lab && ns clean
```

and then rerun the Android command. Repeat for the brand lab if necessary.

If the build fails with:

```
TypeError: webpack.init is not a function
```

upgrade the local NativeScript webpack plugin (the config in this repo expects v5 or newer):

```bash
cd frontend/nativescript/shopper-lab && npm install --save-dev @nativescript/webpack@^5
cd frontend/nativescript/brand-lab && npm install --save-dev @nativescript/webpack@^5
```

Run `ns clean` afterwards to clear stale platforms before executing the `npm run ns:*` scripts again.

Installing `@nativescript/types` keeps TypeScript happy when referencing globals like `android.*`. The repo already includes `references.d.ts` pointing at those definitions.

### Android networking

When testing on a physical device, map the dev servers to the handset:

```bash
adb reverse tcp:3000 tcp:3000
adb reverse tcp:3001 tcp:3001
adb reverse tcp:3100 tcp:3100
adb reverse --list          # verify mappings
```

Alternatively, replace `http://localhost` in the shell with your machine’s LAN IP.

- Real devices treat `localhost` as the phone itself. Either keep the reverse tunnels above running (they persist until the device disconnects) or set `NS_LAB_URL` / `NS_BRAND_URL` to `http://<your-mac-ip>:3001/ar-lab` and rebuild.
- Android emulators can also use `http://10.0.2.2` instead of wiring tunnels.

#### Devices & emulators

The NativeScript CLI requires at least one Android emulator image or a connected device. Common checks:

```bash
ns device android                # lists attached devices
ns device android --available-devices
adb devices                      # quick sanity check
```

If you see:

```
Cannot find connected devices.
Emulator start failed with: No emulator image available for device identifier 'undefined'.
To list currently connected devices and verify that the specified identifier exists, run 'tns device'.
To list available emulator images, run 'tns device <Platform> --available-devices'.
```

then create or launch an Android emulator before rerunning `npm run ns:shopper:android`.

**Create an emulator (Android Studio)**
1. Open Android Studio → More Actions → Virtual Device Manager → `+` Create Device.
2. Pick a Pixel profile, choose an API 34 (Android 14) system image, and download it if prompted.
3. Finish the wizard and press the Play button to boot the virtual device.

**Create from the command line (optional)**
```bash
sdkmanager --install "system-images;android-34;google_apis;x86_64"
avdmanager create avd -n Pixel_6_API_34 -k "system-images;android-34;google_apis;x86_64" --device "pixel_6"
emulator -avd Pixel_6_API_34 &
```

Once the emulator is booted (or a physical device is connected with USB debugging enabled), rerun `ns device android` to confirm it appears, then retry the NativeScript command.
