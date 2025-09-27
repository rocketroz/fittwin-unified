# NativeScript Lab Shells

This directory contains lightweight NativeScript apps that wrap the existing FitTwin web experiences in a native shell. They are designed as stepping stones toward full native AR adapters (ARKit/ARCore) while the measurement lab evolves.

## Projects

- `shopper-lab`: Loads the shopper AR Lab (`/ar-lab`) inside a native WebView. Default URL is controlled by `process.env.NS_LAB_URL` (falls back to `http://localhost:3001/ar-lab`).
- `brand-lab`: Mirrors the brand console for native demos. Default URL is controlled by `process.env.NS_BRAND_URL`.

Each project shares the same structure:

```
app/
  App_Resources/    # icons, splash screens, Info.plist/AndroidManifest overrides
  app-root.xml      # Frame navigation root
  main-page.xml     # WebView hosting the lab UI
  main-page.ts      # view-model handling URL persistence
  app.css           # basic styling to match the web app theme
app.ts               # NativeScript entry point
nsconfig.json        # NativeScript configuration
webpack.config.js    # wires env vars into the bundle
```

## Prerequisites

1. Install the NativeScript CLI globally: `npm install -g nativescript`.
2. Set up platform tooling (Xcode+CocoaPods for iOS, Android SDK/NDK for Android).
3. Ensure the web stack is running (`node scripts/dev-stack.mjs`) so the WebView can reach the lab pages.
4. Export the desired URLs through `NS_LAB_URL` / `NS_BRAND_URL` or edit them in-app.

## Commands

From the repo root:

```bash
npm run ns:shopper:ios      # Run shopper lab on iOS simulator/device
npm run ns:shopper:android  # Run shopper lab on Android emulator/device

npm run ns:brand:ios
npm run ns:brand:android
```

Use these shells to validate navigation, deep links, and native packaging, then progressively replace the WebView with real NativeScript AR components.

### Android specifics

- **Physical device routing**: map the dev server into the device with `adb reverse tcp:3000 tcp:3000` and `adb reverse tcp:3001 tcp:3001` (and `tcp:3100` for the brand portal). Alternatively, replace `http://localhost` in the shell with your machine’s LAN IP.
- **Camera permissions**: the shopper lab requests camera/microphone access automatically when the embedded AR Lab starts capture. Emulators surface a guided placeholder; a real device supplies the live preview.
- **Cleartext traffic**: both shells enable `usesCleartextTraffic` and ship a `network_security_config.xml` so they can reach the local http://localhost endpoints during development.
