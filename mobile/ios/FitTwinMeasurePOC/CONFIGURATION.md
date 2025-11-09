# FitTwin iOS POC - Configuration Guide

**Version**: 1.1.1  
**Last Updated**: 2025-11-09

---

## 📝 Overview

The FitTwin iOS POC uses **Info.plist** for API configuration, following the same pattern as the original FitTwinApp. This allows easy configuration without code changes.

---

## ⚙️ API Configuration

### **Location**

`mobile/ios/FitTwinMeasurePOC/FitTwinMeasure/Info.plist`

### **Configuration Keys**

| Key | Type | Default Value | Description |
|-----|------|---------------|-------------|
| `FITWIN_API_URL` | String | `http://127.0.0.1:8000` | Python measurement API base URL |
| `FITWIN_API_KEY` | String | `staging-secret-key` | API authentication key |

---

## 🔧 Configuration Methods

### **Method 1: Edit Info.plist Directly** (Recommended for Testing)

**File**: `FitTwinMeasure/Info.plist`

```xml
<key>FITWIN_API_URL</key>
<string>http://192.168.1.100:8000</string>  <!-- Your Mac's IP -->

<key>FITWIN_API_KEY</key>
<string>staging-secret-key</string>  <!-- Default key -->
```

**Steps**:
1. Open `Info.plist` in Xcode
2. Find `FITWIN_API_URL` key
3. Change value to your Mac's IP address
4. Save file
5. Rebuild app

---

### **Method 2: Use Xcode Build Settings** (Recommended for Production)

**For different environments** (Debug/Release):

1. **Open Xcode**
2. Select **FitTwinMeasure** target
3. Go to **Build Settings**
4. Add **User-Defined Settings**:
   - `FITWIN_API_URL` = `$(API_URL)`
   - `FITWIN_API_KEY` = `$(API_KEY)`
5. Create **xcconfig files**:

**Debug.xcconfig**:
```
API_URL = http://192.168.1.100:8000
API_KEY = staging-secret-key
```

**Release.xcconfig**:
```
API_URL = https://api.fittwin.com
API_KEY = prod-secret-key-xyz
```

---

## 🚀 Quick Setup for Testing

### **Step 1: Get Your Mac's IP Address**

```bash
ipconfig getifaddr en0
# Example output: 192.168.1.100
```

### **Step 2: Update Info.plist**

**Open**: `FitTwinMeasure/Info.plist`

**Change**:
```xml
<key>FITWIN_API_URL</key>
<string>http://127.0.0.1:8000</string>
```

**To**:
```xml
<key>FITWIN_API_URL</key>
<string>http://192.168.1.100:8000</string>  <!-- Your Mac's IP -->
```

**Keep default API key**:
```xml
<key>FITWIN_API_KEY</key>
<string>staging-secret-key</string>
```

### **Step 3: Rebuild App**

1. Clean build folder: **Product** → **Clean Build Folder** (⇧⌘K)
2. Build and run: **Product** → **Run** (⌘R)

---

## 🔍 How It Works

### **Code Implementation**

**File**: `PythonMeasurementAPI.swift`

```swift
init() {
    // Read from Info.plist (same pattern as original FitTwinApp)
    let bundle = Bundle.main
    let baseURLString = bundle.object(forInfoDictionaryKey: "FITWIN_API_URL") as? String ?? "http://127.0.0.1:8000"
    self.baseURL = baseURLString
    self.apiKey = bundle.object(forInfoDictionaryKey: "FITWIN_API_KEY") as? String ?? "staging-secret-key"
    
    print("⚙️ API Configuration:")
    print("   Base URL: \(baseURL)")
    print("   API Key: \(apiKey.prefix(8))...")
}
```

### **Console Output**

When app starts, you'll see:
```
⚙️ API Configuration:
   Base URL: http://192.168.1.100:8000
   API Key: staging-...
```

This confirms the configuration was loaded correctly.

---

## 🌐 Network Configuration

### **NSAppTransportSecurity**

The Info.plist includes:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Purpose**: Allows HTTP connections (not just HTTPS) for local development.

**⚠️ Security Note**: In production, remove this and use HTTPS only.

---

## 📊 Configuration Scenarios

### **Scenario 1: Local Development (iPhone + Mac)**

**Setup**:
- Python service running on Mac at `localhost:8000`
- iPhone connected to same WiFi as Mac

**Configuration**:
```xml
<key>FITWIN_API_URL</key>
<string>http://192.168.1.100:8000</string>  <!-- Mac's IP -->
<key>FITWIN_API_KEY</key>
<string>staging-secret-key</string>
```

---

### **Scenario 2: Remote Development Server**

**Setup**:
- Python service deployed to staging server
- iPhone on any network with internet

**Configuration**:
```xml
<key>FITWIN_API_URL</key>
<string>https://staging-api.fittwin.com</string>
<key>FITWIN_API_KEY</key>
<string>staging-secret-key</string>
```

---

### **Scenario 3: Production**

**Setup**:
- Python service deployed to production
- App submitted to App Store

**Configuration**:
```xml
<key>FITWIN_API_URL</key>
<string>https://api.fittwin.com</string>
<key>FITWIN_API_KEY</key>
<string>prod-secret-key-xyz</string>
```

**⚠️ Important**: Use HTTPS and remove `NSAllowsArbitraryLoads`.

---

## 🐛 Troubleshooting

### **Issue: "Invalid API URL"**

**Symptom**: App crashes on launch with "Invalid FITWIN_API_URL"

**Solution**:
1. Check Info.plist has `FITWIN_API_URL` key
2. Verify URL format is correct (include `http://` or `https://`)
3. Rebuild app

---

### **Issue: "Connection refused"**

**Symptom**: API calls fail with network error

**Possible Causes**:
1. Python service not running
2. Wrong IP address in Info.plist
3. iPhone and Mac on different networks
4. Firewall blocking connections

**Solution**:
1. Verify Python service is running:
   ```bash
   curl http://localhost:8000/docs
   ```
2. Check Mac's IP address:
   ```bash
   ipconfig getifaddr en0
   ```
3. Ensure iPhone and Mac on same WiFi
4. Update Info.plist with correct IP
5. Rebuild app

---

### **Issue: "API key invalid" (401 error)**

**Symptom**: API returns 401 Unauthorized

**Solution**:
1. Check `FITWIN_API_KEY` in Info.plist
2. Verify it matches Python service's `API_KEY` environment variable
3. Default is `staging-secret-key` (from `services/python/measurement/backend/app/core/config.py`)

---

### **Issue: Configuration not updating**

**Symptom**: Changed Info.plist but app still uses old values

**Solution**:
1. Clean build folder: **Product** → **Clean Build Folder** (⇧⌘K)
2. Delete app from iPhone
3. Rebuild and reinstall

---

## 🔐 Security Best Practices

### **Development**
- ✅ Use `http://` for local testing
- ✅ Use default `staging-secret-key`
- ✅ Allow arbitrary loads in Info.plist

### **Production**
- ✅ Use `https://` only
- ✅ Use strong, unique API key
- ✅ Remove `NSAllowsArbitraryLoads`
- ✅ Store API key in keychain (future enhancement)
- ✅ Implement certificate pinning (future enhancement)

---

## 📝 Configuration Checklist

### **Before Testing**
- [ ] Python service running on Mac
- [ ] Mac's IP address obtained
- [ ] Info.plist updated with Mac's IP
- [ ] API key matches Python service
- [ ] iPhone and Mac on same WiFi
- [ ] App rebuilt after configuration change

### **Before Production**
- [ ] Production API URL configured
- [ ] Production API key configured
- [ ] HTTPS enabled
- [ ] `NSAllowsArbitraryLoads` removed
- [ ] API key security reviewed
- [ ] Network error handling tested

---

## 📚 Related Documentation

- **TESTING_GUIDE.md** - Complete testing procedures
- **MEDIAPIPE_INTEGRATION.md** - Technical implementation
- **CHANGELOG.md** - Version history
- **README.md** - Project overview

---

## 🔗 Python Service Configuration

**Location**: `services/python/measurement/.env`

**Matching Configuration**:
```bash
API_URL=http://localhost:8000
API_KEY=staging-secret-key  # Must match iOS FITWIN_API_KEY
```

**Start Service**:
```bash
cd services/python/measurement
./scripts/dev_server.sh
```

---

## 💡 Tips

1. **Use Mac's IP, not `localhost`**: iPhone can't access `localhost` (that's the iPhone itself)
2. **Same WiFi required**: iPhone and Mac must be on same network
3. **Rebuild after changes**: Xcode caches Info.plist, always rebuild
4. **Check console logs**: Look for "⚙️ API Configuration" to verify settings
5. **Test API first**: Use `curl` to verify Python service before testing iOS app

---

**Last Updated**: 2025-11-09  
**Version**: 1.1.1  
**Pattern**: Matches original FitTwinApp configuration
