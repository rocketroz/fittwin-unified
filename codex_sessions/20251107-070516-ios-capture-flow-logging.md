# ios capture flow logging

- Timestamp: 2025-11-07 07:05:16 PST
- Branch: feature/web-hotfix
- Commit: 4b59c156
- Tags: ios, backend

## Notes
Rewired CaptureFlowViewModel to read FITWIN_API_URL/FITWIN_API_KEY from Info.plist and report network vs HTTP errors clearly.
Added FitTwinAppTests target + shared scheme so xcodebuild test works again.
Reminder: backend must run at FITWIN_API_URL (set to your Mac IP) before using the capture flow on device.

## Git Status
```text
M README.md
 M mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.pbxproj
 M mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate
 M mobile/ios/FitTwinApp/FitTwinApp/CaptureFlow/CaptureFlowViewModel.swift
 M mobile/ios/FitTwinApp/FitTwinApp/Resources/Info.plist
 M scripts/dev-stack.mjs
 M services/python/measurement/scripts/test_all.sh
 M supabase/migrations/002_measurement_provenance.sql
 M supabase/migrations/003_commerce_tables.sql
 M supabase/migrations/004_brand_tables.sql
 M supabase/migrations/005_referral_tables.sql
 M supabase/migrations/006_auth_enhancements.sql
 M supabase/migrations/007_referrals_and_brand_admins.sql
?? agents/
?? codex_sessions/
?? dev-stack.log
?? dev-stack.pid
?? mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/xcshareddata/
?? mobile/ios/FitTwinApp/FitTwinAppTests/
?? screenshots_local/
?? supabase/migrations/001_enable_uuid_extension.sql
?? tmp-postgres/
```

## Git Diff
```diff
diff --git a/README.md b/README.md
index 6632f941..13eee69e 100644
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
+
 # FitTwin Platform
 
 FitTwin is a monorepo that bundles the NestJS backend, Next.js shopper and brand portals, and NativeScript lab shells used for native demos. This README captures how we spin up the full stack locally and the tooling you need around it.
@@ -103,6 +104,8 @@ The Nest backend now supports two Postgres targets:
 `DATABASE_MODE` defaults to `local` if omitted; override TLS/SSL settings via standard TypeORM options when you introduce the shared `DatabaseModule`.
 
 ## NativeScript lab shells
+## iOS ##
+ Laura Tornga device name: Laura Tornga’s iPhone (18.6.2) with UDID 00008140-000C75D61E82801C.
 
 Run these from the repo root after the web stack is live:
 
diff --git a/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.pbxproj b/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.pbxproj
index 5c3d1588..346ea095 100644
--- a/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.pbxproj
+++ b/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.pbxproj
@@ -16,8 +16,19 @@
 		6A0F0F5C29F8C69700A1B2C3 /* CaptureSessionState.swift in Sources */ = {isa = PBXBuildFile; fileRef = 6A0F0F5C29F8C69200A1B2C3 /* CaptureSessionState.swift */; };
 		6A0F0F5C29F8C69800A1B2C3 /* CameraPermissionManager.swift in Sources */ = {isa = PBXBuildFile; fileRef = 6A0F0F5C29F8C69300A1B2C3 /* CameraPermissionManager.swift */; };
 		6A0F0F5C29F8C69A00A1B2C3 /* ARKit.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 6A0F0F5C29F8C69900A1B2C3 /* ARKit.framework */; };
+		6A0F0F5C29F8C7A300A1B2C3 /* FitTwinAppTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = 6A0F0F5C29F8C7A100A1B2C3 /* FitTwinAppTests.swift */; };
 /* End PBXBuildFile section */
 
+/* Begin PBXContainerItemProxy section */
+		6A0F0F5C29F8C7A900A1B2C3 /* PBXContainerItemProxy */ = {
+			isa = PBXContainerItemProxy;
+			containerPortal = 6A0F0F5C29F8C60D00A1B2C3 /* Project object */;
+			proxyType = 1;
+			remoteGlobalIDString = 6A0F0F5C29F8C60F00A1B2C3;
+			remoteInfo = FitTwinApp;
+		};
+/* End PBXContainerItemProxy section */
+
 /* Begin PBXFileReference section */
 		6A0F0F5C29F8C64F00A1B2C3 /* FitTwinApp.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = FitTwinApp.app; sourceTree = BUILT_PRODUCTS_DIR; };
 		6A0F0F5C29F8C65000A1B2C3 /* FitTwinAppApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FitTwinAppApp.swift; sourceTree = "<group>"; };
@@ -30,6 +41,9 @@
 		6A0F0F5C29F8C69200A1B2C3 /* CaptureSessionState.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CaptureSessionState.swift; sourceTree = "<group>"; };
 		6A0F0F5C29F8C69300A1B2C3 /* CameraPermissionManager.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CameraPermissionManager.swift; sourceTree = "<group>"; };
 		6A0F0F5C29F8C69900A1B2C3 /* ARKit.framework */ = {isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = ARKit.framework; path = System/Library/Frameworks/ARKit.framework; sourceTree = SDKROOT; };
+		6A0F0F5C29F8C7A100A1B2C3 /* FitTwinAppTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FitTwinAppTests.swift; sourceTree = "<group>"; };
+		6A0F0F5C29F8C7A200A1B2C3 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
+		6A0F0F5C29F8C7A500A1B2C3 /* FitTwinAppTests.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = FitTwinAppTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
 /* End PBXFileReference section */
 
 /* Begin PBXFrameworksBuildPhase section */
@@ -41,6 +55,13 @@
 			);
 			runOnlyForDeploymentPostprocessing = 0;
 		};
+		6A0F0F5C29F8C7A700A1B2C3 /* Frameworks */ = {
+			isa = PBXFrameworksBuildPhase;
+			buildActionMask = 2147483647;
+			files = (
+			);
+			runOnlyForDeploymentPostprocessing = 0;
+		};
 /* End PBXFrameworksBuildPhase section */
 
 /* Begin PBXGroup section */
@@ -48,6 +69,7 @@
 			isa = PBXGroup;
 			children = (
 				6A0F0F5C29F8C65400A1B2C3 /* FitTwinApp */,
+				6A0F0F5C29F8C7A000A1B2C3 /* FitTwinAppTests */,
 				6A0F0F5C29F8C69B00A1B2C3 /* Frameworks */,
 				6A0F0F5C29F8C61200A1B2C3 /* Products */,
 			);
@@ -57,6 +79,7 @@
 			isa = PBXGroup;
 			children = (
 				6A0F0F5C29F8C64F00A1B2C3 /* FitTwinApp.app */,
+				6A0F0F5C29F8C7A500A1B2C3 /* FitTwinAppTests.xctest */,
 			);
 			name = Products;
 			sourceTree = "<group>";
@@ -93,6 +116,15 @@
 			name = Frameworks;
 			sourceTree = "<group>";
 		};
+		6A0F0F5C29F8C7A000A1B2C3 /* FitTwinAppTests */ = {
+			isa = PBXGroup;
+			children = (
+				6A0F0F5C29F8C7A100A1B2C3 /* FitTwinAppTests.swift */,
+				6A0F0F5C29F8C7A200A1B2C3 /* Info.plist */,
+			);
+			path = FitTwinAppTests;
+			sourceTree = "<group>";
+		};
 /* End PBXGroup section */
 
 /* Begin PBXNativeTarget section */
@@ -113,6 +145,24 @@
 			productReference = 6A0F0F5C29F8C64F00A1B2C3 /* FitTwinApp.app */;
 			productType = "com.apple.product-type.application";
 		};
+		6A0F0F5C29F8C7A400A1B2C3 /* FitTwinAppTests */ = {
+			isa = PBXNativeTarget;
+			buildConfigurationList = 6A0F0F5C29F8C7AD00A1B2C3 /* Build configuration list for PBXNativeTarget "FitTwinAppTests" */;
+			buildPhases = (
+				6A0F0F5C29F8C7A600A1B2C3 /* Sources */,
+				6A0F0F5C29F8C7A700A1B2C3 /* Frameworks */,
+				6A0F0F5C29F8C7A800A1B2C3 /* Resources */,
+			);
+			buildRules = (
+			);
+			dependencies = (
+				6A0F0F5C29F8C7AA00A1B2C3 /* PBXTargetDependency */,
+			);
+			name = FitTwinAppTests;
+			productName = FitTwinAppTests;
+			productReference = 6A0F0F5C29F8C7A500A1B2C3 /* FitTwinAppTests.xctest */;
+			productType = "com.apple.product-type.bundle.unit-test";
+		};
 /* End PBXNativeTarget section */
 
 /* Begin PBXProject section */
@@ -142,6 +192,7 @@
 			projectRoot = "";
 			targets = (
 				6A0F0F5C29F8C60F00A1B2C3 /* FitTwinApp */,
+				6A0F0F5C29F8C7A400A1B2C3 /* FitTwinAppTests */,
 			);
 		};
 /* End PBXProject section */
@@ -156,6 +207,13 @@
 			);
 			runOnlyForDeploymentPostprocessing = 0;
 		};
+		6A0F0F5C29F8C7A800A1B2C3 /* Resources */ = {
+			isa = PBXResourcesBuildPhase;
+			buildActionMask = 2147483647;
+			files = (
+			);
+			runOnlyForDeploymentPostprocessing = 0;
+		};
 /* End PBXResourcesBuildPhase section */
 
 /* Begin PBXSourcesBuildPhase section */
@@ -172,8 +230,24 @@
 			);
 			runOnlyForDeploymentPostprocessing = 0;
 		};
+		6A0F0F5C29F8C7A600A1B2C3 /* Sources */ = {
+			isa = PBXSourcesBuildPhase;
+			buildActionMask = 2147483647;
+			files = (
+				6A0F0F5C29F8C7A300A1B2C3 /* FitTwinAppTests.swift in Sources */,
+			);
+			runOnlyForDeploymentPostprocessing = 0;
+		};
 /* End PBXSourcesBuildPhase section */
 
+/* Begin PBXTargetDependency section */
+		6A0F0F5C29F8C7AA00A1B2C3 /* PBXTargetDependency */ = {
+			isa = PBXTargetDependency;
+			target = 6A0F0F5C29F8C60F00A1B2C3 /* FitTwinApp */;
+			targetProxy = 6A0F0F5C29F8C7A900A1B2C3 /* PBXContainerItemProxy */;
+		};
+/* End PBXTargetDependency section */
+
 /* Begin XCBuildConfiguration section */
 		6A0F0F5C29F8C67000A1B2C3 /* Debug */ = {
 			isa = XCBuildConfiguration;
@@ -355,6 +429,44 @@
 			};
 			name = Release;
 		};
+		6A0F0F5C29F8C7AB00A1B2C3 /* Debug */ = {
+			isa = XCBuildConfiguration;
+			buildSettings = {
+				BUNDLE_LOADER = "$(TEST_HOST)";
+				INFOPLIST_FILE = FitTwinAppTests/Info.plist;
+				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
+				LD_RUNPATH_SEARCH_PATHS = (
+					"$(inherited)",
+					"@executable_path/Frameworks",
+					"@loader_path/Frameworks",
+				);
+				PRODUCT_BUNDLE_IDENTIFIER = com.lauratornga.fittwin.appTests;
+				PRODUCT_NAME = "$(TARGET_NAME)";
+				SWIFT_VERSION = 5.0;
+				TARGETED_DEVICE_FAMILY = "1,2";
+				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/FitTwinApp.app/FitTwinApp";
+			};
+			name = Debug;
+		};
+		6A0F0F5C29F8C7AC00A1B2C3 /* Release */ = {
+			isa = XCBuildConfiguration;
+			buildSettings = {
+				BUNDLE_LOADER = "$(TEST_HOST)";
+				INFOPLIST_FILE = FitTwinAppTests/Info.plist;
+				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
+				LD_RUNPATH_SEARCH_PATHS = (
+					"$(inherited)",
+					"@executable_path/Frameworks",
+					"@loader_path/Frameworks",
+				);
+				PRODUCT_BUNDLE_IDENTIFIER = com.lauratornga.fittwin.appTests;
+				PRODUCT_NAME = "$(TARGET_NAME)";
+				SWIFT_VERSION = 5.0;
+				TARGETED_DEVICE_FAMILY = "1,2";
+				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/FitTwinApp.app/FitTwinApp";
+			};
+			name = Release;
+		};
 /* End XCBuildConfiguration section */
 
 /* Begin XCConfigurationList section */
@@ -376,6 +488,15 @@
 			defaultConfigurationIsVisible = 0;
 			defaultConfigurationName = Release;
 		};
+		6A0F0F5C29F8C7AD00A1B2C3 /* Build configuration list for PBXNativeTarget "FitTwinAppTests" */ = {
+			isa = XCConfigurationList;
+			buildConfigurations = (
+				6A0F0F5C29F8C7AB00A1B2C3 /* Debug */,
+				6A0F0F5C29F8C7AC00A1B2C3 /* Release */,
+			);
+			defaultConfigurationIsVisible = 0;
+			defaultConfigurationName = Release;
+		};
 /* End XCConfigurationList section */
 	};
 	rootObject = 6A0F0F5C29F8C60D00A1B2C3 /* Project object */;
diff --git a/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate b/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate
index 57867c34..47e172ad 100644
Binary files a/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate and b/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate differ
diff --git a/mobile/ios/FitTwinApp/FitTwinApp/CaptureFlow/CaptureFlowViewModel.swift b/mobile/ios/FitTwinApp/FitTwinApp/CaptureFlow/CaptureFlowViewModel.swift
index 8a2b8280..4ebe8f18 100644
--- a/mobile/ios/FitTwinApp/FitTwinApp/CaptureFlow/CaptureFlowViewModel.swift
+++ b/mobile/ios/FitTwinApp/FitTwinApp/CaptureFlow/CaptureFlowViewModel.swift
@@ -6,10 +6,15 @@ final class CaptureFlowViewModel: ObservableObject {
     @Published var alertMessage: String?
 
     private let permissionManager = CameraPermissionManager()
-    
-    // ✅ ADD THIS: Backend API configuration
-    private let apiBaseURL = "http://192.168.4.208:8000"
-    private let apiKey = "7c4b71191d6026973900ac353d6d68ac5977836cc85710a04ccf3ba147db301e"
+    private let apiBaseURL: URL
+    private let apiKey: String
+
+    init() {
+        let bundle = Bundle.main
+        let urlString = bundle.object(forInfoDictionaryKey: "FITWIN_API_URL") as? String ?? "http://127.0.0.1:8000"
+        apiBaseURL = URL(string: urlString)?.appendingPathComponent("measurements/validate") ?? URL(string: "http://127.0.0.1:8000/measurements/validate")!
+        apiKey = bundle.object(forInfoDictionaryKey: "FITWIN_API_KEY") as? String ?? "staging-secret-key"
+    }
 
     func startFlow( ) {
         Task {
@@ -52,9 +57,8 @@ final class CaptureFlowViewModel: ObservableObject {
 
     // ✅ UPDATED: Real backend API call
     private func processMeasurements() async {
-        print("🔵 Starting processMeasurements...")
-        print("🔵 API URL: \(apiBaseURL)/measurements/validate")
-        print("🔵 API Key: \(apiKey)")
+        print("🔵 Starting processMeasurements…")
+        print("🔵 API URL: \(apiBaseURL.absoluteString)")
         
         do {
             // Create measurement data
@@ -75,14 +79,7 @@ final class CaptureFlowViewModel: ObservableObject {
             print("🔵 JSON data created, size: \(jsonData.count) bytes")
             
             // Create URL
-            guard let url = URL(string: "\(apiBaseURL)/measurements/validate") else {
-                print("❌ Failed to create URL")
-                throw NSError(domain: "Invalid URL", code: -1)
-            }
-            print("🔵 URL created: \(url)")
-            
-            // Create request
-            var request = URLRequest(url: url)
+            var request = URLRequest(url: apiBaseURL)
             request.httpMethod = "POST"
             request.setValue("application/json", forHTTPHeaderField: "Content-Type" )
             request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
@@ -117,12 +114,21 @@ final class CaptureFlowViewModel: ObservableObject {
                 throw NSError(domain: "API Error", code: httpResponse.statusCode )
             }
             
+        } catch let urlError as URLError {
+            let message = "Network error: \(urlError.localizedDescription). Make sure the backend at \(apiBaseURL.absoluteString) is reachable from your device."
+            state = .error(message)
+            alertMessage = message
+            print("❌ URLError: \(urlError)")
+        } catch let apiError as NSError where apiError.domain == "API Error" {
+            let message = "Backend rejected the request (HTTP \(apiError.code)). Check the FastAPI logs for the detailed error."
+            state = .error(message)
+            alertMessage = message
+            print("❌ API Error: status=\(apiError.code)")
         } catch {
             let message = "Failed to process measurements: \(error.localizedDescription)"
             state = .error(message)
             alertMessage = message
             print("❌ Error:", error)
-            print("❌ Error details:", error)
         }
     }
 
@@ -131,5 +137,3 @@ final class CaptureFlowViewModel: ObservableObject {
         alertMessage = nil
     }
 }
-
-
diff --git a/mobile/ios/FitTwinApp/FitTwinApp/Resources/Info.plist b/mobile/ios/FitTwinApp/FitTwinApp/Resources/Info.plist
index 409380b1..f231fd40 100644
--- a/mobile/ios/FitTwinApp/FitTwinApp/Resources/Info.plist
+++ b/mobile/ios/FitTwinApp/FitTwinApp/Resources/Info.plist
@@ -18,8 +18,17 @@
 	<string>1.0</string>
 	<key>CFBundleVersion</key>
 	<string>1</string>
+	<key>FITWIN_API_KEY</key>
+	<string>staging-secret-key</string>
+	<key>FITWIN_API_URL</key>
+	<string>http://127.0.0.1:8000</string>
 	<key>LSRequiresIPhoneOS</key>
 	<true/>
+	<key>NSAppTransportSecurity</key>
+	<dict>
+		<key>NSAllowsArbitraryLoads</key>
+		<true/>
+	</dict>
 	<key>NSCameraUsageDescription</key>
 	<string>FitTwin needs access to the camera to capture measurement photos.</string>
 	<key>NSMicrophoneUsageDescription</key>
@@ -37,11 +46,6 @@
 		<string>UIInterfaceOrientationLandscapeLeft</string>
 		<string>UIInterfaceOrientationLandscapeRight</string>
 	</array>
-	<key>NSAppTransportSecurity</key>
-	<dict>
-		<key>NSAllowsArbitraryLoads</key>
-		<true/>
-	</dict>
 	<key>UISupportedInterfaceOrientations~ipad</key>
 	<array>
 		<string>UIInterfaceOrientationPortrait</string>
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
diff --git a/supabase/migrations/002_measurement_provenance.sql b/supabase/migrations/002_measurement_provenance.sql
index 6587b849..0c107b5e 100644
--- a/supabase/migrations/002_measurement_provenance.sql
+++ b/supabase/migrations/002_measurement_provenance.sql
@@ -1,54 +1,77 @@
--- Supabase migration for measurement provenance storage (Manus package).
-
-create table if not exists measurement_sessions (
-    id uuid primary key default uuid_generate_v4(),
-    session_id text unique not null,
-    source_type text default 'mediapipe_web',
-    platform text default 'web_mobile',
-    device_id text,
-    front_photo_url text,
-    side_photo_url text,
-    created_at timestamptz default timezone('utc', now())
-);
-
-create table if not exists mediapipe_landmarks (
-    id uuid primary key default uuid_generate_v4(),
-    session_id text not null references measurement_sessions(session_id) on delete cascade,
-    view text not null check (view in ('front', 'side')),
-    landmarks jsonb not null,
-    image_width integer,
-    image_height integer,
-    timestamp timestamptz,
-    created_at timestamptz default timezone('utc', now())
-);
-
-create table if not exists normalized_measurements (
-    id uuid primary key default uuid_generate_v4(),
-    session_id text not null references measurement_sessions(session_id) on delete cascade,
-    payload jsonb not null,
-    source text default 'mediapipe',
-    model_version text default 'v1.0-mediapipe',
-    confidence numeric,
-    accuracy_estimate numeric,
-    created_at timestamptz default timezone('utc', now())
-);
-
-create index if not exists idx_measurement_sessions_created_at on measurement_sessions(created_at);
-create index if not exists idx_mediapipe_landmarks_session_view on mediapipe_landmarks(session_id, view);
-create index if not exists idx_normalized_measurements_session on normalized_measurements(session_id);
+-- Ensure Supabase auth schema exists locally (noop in hosted Supabase)
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM information_schema.schemata WHERE schema_name = 'auth'
+    ) THEN
+        EXECUTE 'CREATE SCHEMA auth';
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM information_schema.tables
+        WHERE table_schema = 'auth' AND table_name = 'users'
+    ) THEN
+        EXECUTE $DDL$
+            CREATE TABLE auth.users (
+                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
+                email TEXT,
+                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
+            )
+        $DDL$;
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1
+        FROM pg_proc p
+        JOIN pg_namespace n ON n.oid = p.pronamespace
+        WHERE n.nspname = 'auth' AND p.proname = 'uid'
+    ) THEN
+        EXECUTE $DDL$
+            CREATE FUNCTION auth.uid()
+            RETURNS UUID
+            LANGUAGE SQL
+            STABLE
+            AS $FUNC$ SELECT NULL::uuid $FUNC$
+        $DDL$;
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1
+        FROM pg_proc p
+        JOIN pg_namespace n ON n.oid = p.pronamespace
+        WHERE n.nspname = 'auth' AND p.proname = 'jwt'
+    ) THEN
+        EXECUTE $DDL$
+            CREATE FUNCTION auth.jwt()
+            RETURNS JSONB
+            LANGUAGE SQL
+            STABLE
+            AS $FUNC$ SELECT jsonb_build_object('role', 'anon') $FUNC$
+        $DDL$;
+    END IF;
+END
+$$;
 
-comment on table measurement_sessions is 'Stores high-level session metadata and provenance.';
-comment on table mediapipe_landmarks is 'Stores raw MediaPipe landmark payloads for replay/calibration.';
-comment on table normalized_measurements is 'Stores normalized measurement outputs with accuracy metadata.';
 -- Migration: Measurement Provenance Schema
 -- Description: Create tables for storing measurement provenance, including raw photos,
 --              MediaPipe landmarks, calculated measurements, and size recommendations.
 -- Date: 2025-10-27
 -- Author: Manus AI
 
--- Measurement sessions table
-CREATE TABLE measurement_sessions (
-    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
+CREATE TABLE IF NOT EXISTS measurement_sessions (
+    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     user_id UUID REFERENCES auth.users(id),
     session_id TEXT UNIQUE NOT NULL,
     source_type TEXT NOT NULL DEFAULT 'mediapipe_web', -- arkit_lidar, mediapipe_native, mediapipe_web, user_input
@@ -64,9 +87,9 @@ CREATE TABLE measurement_sessions (
 );
 
 -- Raw photos table
-CREATE TABLE measurement_photos (
-    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
-    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
+CREATE TABLE IF NOT EXISTS measurement_photos (
+    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
+    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
     photo_type TEXT NOT NULL, -- front, side
     photo_url TEXT NOT NULL,
     uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
@@ -75,9 +98,9 @@ CREATE TABLE measurement_photos (
 );
 
 -- MediaPipe landmarks table
-CREATE TABLE mediapipe_landmarks (
-    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
-    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
+CREATE TABLE IF NOT EXISTS mediapipe_landmarks (
+    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
+    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
     photo_id UUID REFERENCES measurement_photos(id) ON DELETE CASCADE,
     landmark_type TEXT NOT NULL, -- front, side
     landmarks JSONB NOT NULL, -- Array of {x, y, z, visibility}
@@ -86,9 +109,9 @@ CREATE TABLE mediapipe_landmarks (
 );
 
 -- Calculated measurements table (MediaPipe-derived)
-CREATE TABLE measurements_mediapipe (
-    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
-    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
+CREATE TABLE IF NOT EXISTS measurements_mediapipe (
+    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
+    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
     height_cm FLOAT NOT NULL,
     neck_cm FLOAT,
     shoulder_cm FLOAT,
@@ -114,9 +137,9 @@ CREATE TABLE measurements_mediapipe (
 );
 
 -- Vendor measurements table (for calibration only, if needed)
-CREATE TABLE measurements_vendor (
-    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
-    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
+CREATE TABLE IF NOT EXISTS measurements_vendor (
+    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
+    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
     vendor_name TEXT NOT NULL, -- 3dlook, nettelo, etc.
     vendor_version TEXT,
     measurements JSONB NOT NULL, -- Raw vendor JSON response
@@ -128,9 +151,9 @@ CREATE TABLE measurements_vendor (
 );
 
 -- Size recommendations table
-CREATE TABLE size_recommendations (
-    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
-    session_id UUID REFERENCES measurement_sessions(id) ON DELETE CASCADE,
+CREATE TABLE IF NOT EXISTS size_recommendations (
+    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
+    session_id TEXT REFERENCES measurement_sessions(session_id) ON DELETE CASCADE,
     measurement_id UUID REFERENCES measurements_mediapipe(id) ON DELETE CASCADE,
     category TEXT NOT NULL, -- tops, bottoms, dresses, etc.
     size TEXT NOT NULL,
@@ -140,14 +163,102 @@ CREATE TABLE size_recommendations (
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
+ALTER TABLE measurement_sessions
+    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id),
+    ADD COLUMN IF NOT EXISTS browser_info JSONB,
+    ADD COLUMN IF NOT EXISTS processing_location TEXT,
+    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
+    ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending',
+    ADD COLUMN IF NOT EXISTS accuracy_estimate FLOAT,
+    ADD COLUMN IF NOT EXISTS needs_calibration BOOLEAN DEFAULT FALSE;
+
 -- Indexes for performance
-CREATE INDEX idx_sessions_user ON measurement_sessions(user_id);
-CREATE INDEX idx_sessions_session_id ON measurement_sessions(session_id);
-CREATE INDEX idx_photos_session ON measurement_photos(session_id);
-CREATE INDEX idx_landmarks_session ON mediapipe_landmarks(session_id);
-CREATE INDEX idx_measurements_session ON measurements_mediapipe(session_id);
-CREATE INDEX idx_vendor_session ON measurements_vendor(session_id);
-CREATE INDEX idx_recommendations_session ON size_recommendations(session_id);
+CREATE INDEX IF NOT EXISTS idx_sessions_user ON measurement_sessions(user_id);
+CREATE INDEX IF NOT EXISTS idx_sessions_session_id ON measurement_sessions(session_id);
+CREATE INDEX IF NOT EXISTS idx_photos_session ON measurement_photos(session_id);
+CREATE INDEX IF NOT EXISTS idx_landmarks_session ON mediapipe_landmarks(session_id);
+CREATE INDEX IF NOT EXISTS idx_measurements_session ON measurements_mediapipe(session_id);
+CREATE INDEX IF NOT EXISTS idx_vendor_session ON measurements_vendor(session_id);
+CREATE INDEX IF NOT EXISTS idx_recommendations_session ON size_recommendations(session_id);
+
+-- Drop existing policies that reference session_id before altering column types
+DROP POLICY IF EXISTS "Users can view own photos" ON measurement_photos;
+DROP POLICY IF EXISTS "Users can insert own photos" ON measurement_photos;
+DROP POLICY IF EXISTS "Users can view own landmarks" ON mediapipe_landmarks;
+DROP POLICY IF EXISTS "Users can insert own landmarks" ON mediapipe_landmarks;
+DROP POLICY IF EXISTS "Users can view own measurements" ON measurements_mediapipe;
+DROP POLICY IF EXISTS "Users can insert own measurements" ON measurements_mediapipe;
+DROP POLICY IF EXISTS "Users can view own recommendations" ON size_recommendations;
+
+DO $$
+BEGIN
+    IF EXISTS (
+        SELECT 1 FROM information_schema.columns
+        WHERE table_schema = 'public' AND table_name = 'measurement_photos'
+          AND column_name = 'session_id' AND data_type = 'uuid'
+    ) THEN
+        EXECUTE 'ALTER TABLE measurement_photos DROP CONSTRAINT IF EXISTS measurement_photos_session_id_fkey';
+        EXECUTE 'ALTER TABLE measurement_photos ALTER COLUMN session_id TYPE text USING session_id::text';
+        EXECUTE 'ALTER TABLE measurement_photos ADD CONSTRAINT measurement_photos_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF EXISTS (
+        SELECT 1 FROM information_schema.columns
+        WHERE table_schema = 'public' AND table_name = 'mediapipe_landmarks'
+          AND column_name = 'session_id' AND data_type = 'uuid'
+    ) THEN
+        EXECUTE 'ALTER TABLE mediapipe_landmarks DROP CONSTRAINT IF EXISTS mediapipe_landmarks_session_id_fkey';
+        EXECUTE 'ALTER TABLE mediapipe_landmarks ALTER COLUMN session_id TYPE text USING session_id::text';
+        EXECUTE 'ALTER TABLE mediapipe_landmarks ADD CONSTRAINT mediapipe_landmarks_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF EXISTS (
+        SELECT 1 FROM information_schema.columns
+        WHERE table_schema = 'public' AND table_name = 'measurements_mediapipe'
+          AND column_name = 'session_id' AND data_type = 'uuid'
+    ) THEN
+        EXECUTE 'ALTER TABLE measurements_mediapipe DROP CONSTRAINT IF EXISTS measurements_mediapipe_session_id_fkey';
+        EXECUTE 'ALTER TABLE measurements_mediapipe ALTER COLUMN session_id TYPE text USING session_id::text';
+        EXECUTE 'ALTER TABLE measurements_mediapipe ADD CONSTRAINT measurements_mediapipe_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF EXISTS (
+        SELECT 1 FROM information_schema.columns
+        WHERE table_schema = 'public' AND table_name = 'measurements_vendor'
+          AND column_name = 'session_id' AND data_type = 'uuid'
+    ) THEN
+        EXECUTE 'ALTER TABLE measurements_vendor DROP CONSTRAINT IF EXISTS measurements_vendor_session_id_fkey';
+        EXECUTE 'ALTER TABLE measurements_vendor ALTER COLUMN session_id TYPE text USING session_id::text';
+        EXECUTE 'ALTER TABLE measurements_vendor ADD CONSTRAINT measurements_vendor_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF EXISTS (
+        SELECT 1 FROM information_schema.columns
+        WHERE table_schema = 'public' AND table_name = 'size_recommendations'
+          AND column_name = 'session_id' AND data_type = 'uuid'
+    ) THEN
+        EXECUTE 'ALTER TABLE size_recommendations DROP CONSTRAINT IF EXISTS size_recommendations_session_id_fkey';
+        EXECUTE 'ALTER TABLE size_recommendations ALTER COLUMN session_id TYPE text USING session_id::text';
+        EXECUTE 'ALTER TABLE size_recommendations ADD CONSTRAINT size_recommendations_session_id_fkey FOREIGN KEY (session_id) REFERENCES measurement_sessions(session_id) ON DELETE CASCADE';
+    END IF;
+END
+$$;
 
 -- Row Level Security (RLS) policies
 ALTER TABLE measurement_sessions ENABLE ROW LEVEL SECURITY;
@@ -158,71 +269,197 @@ ALTER TABLE measurements_vendor ENABLE ROW LEVEL SECURITY;
 ALTER TABLE size_recommendations ENABLE ROW LEVEL SECURITY;
 
 -- Users can only access their own data
-CREATE POLICY "Users can view own sessions" ON measurement_sessions
-    FOR SELECT USING (auth.uid() = user_id);
-
-CREATE POLICY "Users can insert own sessions" ON measurement_sessions
-    FOR INSERT WITH CHECK (auth.uid() = user_id);
-
-CREATE POLICY "Users can view own photos" ON measurement_photos
-    FOR SELECT USING (
-        session_id IN (SELECT id FROM measurement_sessions WHERE user_id = auth.uid())
-    );
-
-CREATE POLICY "Users can insert own photos" ON measurement_photos
-    FOR INSERT WITH CHECK (
-        session_id IN (SELECT id FROM measurement_sessions WHERE user_id = auth.uid())
-    );
-
-CREATE POLICY "Users can view own landmarks" ON mediapipe_landmarks
-    FOR SELECT USING (
-        session_id IN (SELECT id FROM measurement_sessions WHERE user_id = auth.uid())
-    );
-
-CREATE POLICY "Users can insert own landmarks" ON mediapipe_landmarks
-    FOR INSERT WITH CHECK (
-        session_id IN (SELECT id FROM measurement_sessions WHERE user_id = auth.uid())
-    );
-
-CREATE POLICY "Users can view own measurements" ON measurements_mediapipe
-    FOR SELECT USING (
-        session_id IN (SELECT id FROM measurement_sessions WHERE user_id = auth.uid())
-    );
-
-CREATE POLICY "Users can insert own measurements" ON measurements_mediapipe
-    FOR INSERT WITH CHECK (
-        session_id IN (SELECT id FROM measurement_sessions WHERE user_id = auth.uid())
-    );
-
-CREATE POLICY "Users can view own recommendations" ON size_recommendations
-    FOR SELECT USING (
-        session_id IN (SELECT id FROM measurement_sessions WHERE user_id = auth.uid())
-    );
-
-CREATE POLICY "Users can insert own recommendations" ON size_recommendations
-    FOR INSERT WITH CHECK (
-        session_id IN (SELECT id FROM measurement_sessions WHERE user_id = auth.uid())
-    );
-
--- Vendor measurements are only accessible by service role (for calibration)
-CREATE POLICY "Service role full access vendor" ON measurements_vendor
-    FOR ALL USING (auth.jwt()->>'role' = 'service_role');
-
--- API service role can access all data (for DMaaS API)
-CREATE POLICY "Service role full access sessions" ON measurement_sessions
-    FOR ALL USING (auth.jwt()->>'role' = 'service_role');
-
-CREATE POLICY "Service role full access photos" ON measurement_photos
-    FOR ALL USING (auth.jwt()->>'role' = 'service_role');
-
-CREATE POLICY "Service role full access landmarks" ON mediapipe_landmarks
-    FOR ALL USING (auth.jwt()->>'role' = 'service_role');
-
-CREATE POLICY "Service role full access measurements" ON measurements_mediapipe
-    FOR ALL USING (auth.jwt()->>'role' = 'service_role');
-
-CREATE POLICY "Service role full access recommendations" ON size_recommendations
-    FOR ALL USING (auth.jwt()->>'role' = 'service_role');
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own sessions'
+    ) THEN
+        CREATE POLICY "Users can view own sessions" ON measurement_sessions
+            FOR SELECT USING (auth.uid() = user_id);
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own sessions'
+    ) THEN
+        CREATE POLICY "Users can insert own sessions" ON measurement_sessions
+            FOR INSERT WITH CHECK (auth.uid() = user_id);
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own photos'
+    ) THEN
+        CREATE POLICY "Users can view own photos" ON measurement_photos
+            FOR SELECT USING (
+                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
+            );
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own photos'
+    ) THEN
+        CREATE POLICY "Users can insert own photos" ON measurement_photos
+            FOR INSERT WITH CHECK (
+                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
+            );
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own landmarks'
+    ) THEN
+        CREATE POLICY "Users can view own landmarks" ON mediapipe_landmarks
+            FOR SELECT USING (
+                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
+            );
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own landmarks'
+    ) THEN
+        CREATE POLICY "Users can insert own landmarks" ON mediapipe_landmarks
+            FOR INSERT WITH CHECK (
+                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
+            );
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own measurements'
+    ) THEN
+        CREATE POLICY "Users can view own measurements" ON measurements_mediapipe
+            FOR SELECT USING (
+                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
+            );
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own measurements'
+    ) THEN
+        CREATE POLICY "Users can insert own measurements" ON measurements_mediapipe
+            FOR INSERT WITH CHECK (
+                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
+            );
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can view own recommendations'
+    ) THEN
+        CREATE POLICY "Users can view own recommendations" ON size_recommendations
+            FOR SELECT USING (
+                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
+            );
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own recommendations'
+    ) THEN
+        CREATE POLICY "Users can insert own recommendations" ON size_recommendations
+            FOR INSERT WITH CHECK (
+                session_id IN (SELECT session_id FROM measurement_sessions WHERE user_id = auth.uid())
+            );
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access vendor'
+    ) THEN
+        CREATE POLICY "Service role full access vendor" ON measurements_vendor
+            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access sessions'
+    ) THEN
+        CREATE POLICY "Service role full access sessions" ON measurement_sessions
+            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access photos'
+    ) THEN
+        CREATE POLICY "Service role full access photos" ON measurement_photos
+            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access landmarks'
+    ) THEN
+        CREATE POLICY "Service role full access landmarks" ON mediapipe_landmarks
+            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access measurements'
+    ) THEN
+        CREATE POLICY "Service role full access measurements" ON measurements_mediapipe
+            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
+    END IF;
+END
+$$;
+
+DO $$
+BEGIN
+    IF NOT EXISTS (
+        SELECT 1 FROM pg_policies WHERE policyname = 'Service role full access recommendations'
+    ) THEN
+        CREATE POLICY "Service role full access recommendations" ON size_recommendations
+            FOR ALL USING (auth.jwt()->>'role' = 'service_role');
+    END IF;
+END
+$$;
 
 -- Trigger to update updated_at timestamp
 CREATE OR REPLACE FUNCTION update_updated_at_column()
@@ -233,6 +470,8 @@ BEGIN
 END;
 $$ LANGUAGE plpgsql;
 
+DROP TRIGGER IF EXISTS update_measurement_sessions_updated_at ON measurement_sessions;
+
 CREATE TRIGGER update_measurement_sessions_updated_at
     BEFORE UPDATE ON measurement_sessions
     FOR EACH ROW
@@ -245,4 +484,3 @@ COMMENT ON TABLE mediapipe_landmarks IS 'Stores MediaPipe Pose landmarks for mea
 COMMENT ON TABLE measurements_mediapipe IS 'Stores calculated measurements from MediaPipe landmarks';
 COMMENT ON TABLE measurements_vendor IS 'Stores vendor API measurements for calibration only (excluded from live)';
 COMMENT ON TABLE size_recommendations IS 'Stores size recommendations generated from measurements';
-
diff --git a/supabase/migrations/003_commerce_tables.sql b/supabase/migrations/003_commerce_tables.sql
index 5befeaf9..e00cb1f9 100644
--- a/supabase/migrations/003_commerce_tables.sql
+++ b/supabase/migrations/003_commerce_tables.sql
@@ -17,7 +17,7 @@ CREATE TABLE IF NOT EXISTS carts (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_carts_user_id ON carts(user_id);
+CREATE INDEX IF NOT EXISTS idx_carts_user_id ON carts(user_id);
 
 -- ============================================================================
 -- CART ITEMS
@@ -34,8 +34,8 @@ CREATE TABLE IF NOT EXISTS cart_items (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_cart_items_cart_id ON cart_items(cart_id);
-CREATE INDEX idx_cart_items_product_id ON cart_items(product_id);
+CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON cart_items(cart_id);
+CREATE INDEX IF NOT EXISTS idx_cart_items_product_id ON cart_items(product_id);
 
 -- ============================================================================
 -- ADDRESSES
@@ -58,8 +58,8 @@ CREATE TABLE IF NOT EXISTS addresses (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_addresses_user_id ON addresses(user_id);
-CREATE INDEX idx_addresses_user_default ON addresses(user_id, is_default);
+CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON addresses(user_id);
+CREATE INDEX IF NOT EXISTS idx_addresses_user_default ON addresses(user_id, is_default);
 
 -- ============================================================================
 -- PAYMENT METHODS
@@ -80,8 +80,8 @@ CREATE TABLE IF NOT EXISTS payment_methods (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_payment_methods_user_id ON payment_methods(user_id);
-CREATE INDEX idx_payment_methods_user_default ON payment_methods(user_id, is_default);
+CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON payment_methods(user_id);
+CREATE INDEX IF NOT EXISTS idx_payment_methods_user_default ON payment_methods(user_id, is_default);
 
 -- ============================================================================
 -- ORDERS
@@ -115,10 +115,10 @@ CREATE TABLE IF NOT EXISTS orders (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_orders_user_id ON orders(user_id);
-CREATE INDEX idx_orders_status ON orders(status);
-CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
-CREATE INDEX idx_orders_referral_id ON orders(referral_id);
+CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
+CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
+CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
+CREATE INDEX IF NOT EXISTS idx_orders_referral_id ON orders(referral_id);
 
 -- ============================================================================
 -- ORDER ITEMS
@@ -140,8 +140,8 @@ CREATE TABLE IF NOT EXISTS order_items (
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_order_items_order_id ON order_items(order_id);
-CREATE INDEX idx_order_items_product_id ON order_items(product_id);
+CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
+CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);
 
 -- ============================================================================
 -- CHECKOUT INTENTS (for idempotency)
@@ -155,7 +155,7 @@ CREATE TABLE IF NOT EXISTS checkout_intents (
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_checkout_intents_order_id ON checkout_intents(order_id);
+CREATE INDEX IF NOT EXISTS idx_checkout_intents_order_id ON checkout_intents(order_id);
 
 -- ============================================================================
 -- ROW-LEVEL SECURITY (RLS) POLICIES
@@ -171,87 +171,107 @@ ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
 ALTER TABLE checkout_intents ENABLE ROW LEVEL SECURITY;
 
 -- Carts: Users can only access their own carts
+DROP POLICY IF EXISTS "Users can view their own carts" ON carts;
 CREATE POLICY "Users can view their own carts"
     ON carts FOR SELECT
     USING (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can insert their own carts" ON carts;
 CREATE POLICY "Users can insert their own carts"
     ON carts FOR INSERT
     WITH CHECK (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can update their own carts" ON carts;
 CREATE POLICY "Users can update their own carts"
     ON carts FOR UPDATE
     USING (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can delete their own carts" ON carts;
 CREATE POLICY "Users can delete their own carts"
     ON carts FOR DELETE
     USING (auth.uid() = user_id);
 
 -- Cart Items: Users can only access items in their own carts
+DROP POLICY IF EXISTS "Users can view their own cart items" ON cart_items;
 CREATE POLICY "Users can view their own cart items"
     ON cart_items FOR SELECT
     USING (cart_id IN (SELECT id FROM carts WHERE user_id = auth.uid()));
 
+DROP POLICY IF EXISTS "Users can insert their own cart items" ON cart_items;
 CREATE POLICY "Users can insert their own cart items"
     ON cart_items FOR INSERT
     WITH CHECK (cart_id IN (SELECT id FROM carts WHERE user_id = auth.uid()));
 
+DROP POLICY IF EXISTS "Users can update their own cart items" ON cart_items;
 CREATE POLICY "Users can update their own cart items"
     ON cart_items FOR UPDATE
     USING (cart_id IN (SELECT id FROM carts WHERE user_id = auth.uid()));
 
+DROP POLICY IF EXISTS "Users can delete their own cart items" ON cart_items;
 CREATE POLICY "Users can delete their own cart items"
     ON cart_items FOR DELETE
     USING (cart_id IN (SELECT id FROM carts WHERE user_id = auth.uid()));
 
 -- Addresses: Users can only access their own addresses
+DROP POLICY IF EXISTS "Users can view their own addresses" ON addresses;
 CREATE POLICY "Users can view their own addresses"
     ON addresses FOR SELECT
     USING (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can insert their own addresses" ON addresses;
 CREATE POLICY "Users can insert their own addresses"
     ON addresses FOR INSERT
     WITH CHECK (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can update their own addresses" ON addresses;
 CREATE POLICY "Users can update their own addresses"
     ON addresses FOR UPDATE
     USING (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can delete their own addresses" ON addresses;
 CREATE POLICY "Users can delete their own addresses"
     ON addresses FOR DELETE
     USING (auth.uid() = user_id);
 
 -- Payment Methods: Users can only access their own payment methods
+DROP POLICY IF EXISTS "Users can view their own payment methods" ON payment_methods;
 CREATE POLICY "Users can view their own payment methods"
     ON payment_methods FOR SELECT
     USING (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can insert their own payment methods" ON payment_methods;
 CREATE POLICY "Users can insert their own payment methods"
     ON payment_methods FOR INSERT
     WITH CHECK (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can update their own payment methods" ON payment_methods;
 CREATE POLICY "Users can update their own payment methods"
     ON payment_methods FOR UPDATE
     USING (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can delete their own payment methods" ON payment_methods;
 CREATE POLICY "Users can delete their own payment methods"
     ON payment_methods FOR DELETE
     USING (auth.uid() = user_id);
 
 -- Orders: Users can only access their own orders
+DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
 CREATE POLICY "Users can view their own orders"
     ON orders FOR SELECT
     USING (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
 CREATE POLICY "Users can insert their own orders"
     ON orders FOR INSERT
     WITH CHECK (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
 CREATE POLICY "Users can update their own orders"
     ON orders FOR UPDATE
     USING (auth.uid() = user_id);
 
 -- Order Items: Users can only access items in their own orders
+DROP POLICY IF EXISTS "Users can view their own order items" ON order_items;
 CREATE POLICY "Users can view their own order items"
     ON order_items FOR SELECT
     USING (order_id IN (SELECT id FROM orders WHERE user_id = auth.uid()));
@@ -273,26 +293,31 @@ END;
 $$ LANGUAGE plpgsql;
 
 -- Triggers for updated_at
+DROP TRIGGER IF EXISTS update_carts_updated_at ON carts;
 CREATE TRIGGER update_carts_updated_at
     BEFORE UPDATE ON carts
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_cart_items_updated_at ON cart_items;
 CREATE TRIGGER update_cart_items_updated_at
     BEFORE UPDATE ON cart_items
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_addresses_updated_at ON addresses;
 CREATE TRIGGER update_addresses_updated_at
     BEFORE UPDATE ON addresses
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_payment_methods_updated_at ON payment_methods;
 CREATE TRIGGER update_payment_methods_updated_at
     BEFORE UPDATE ON payment_methods
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
 CREATE TRIGGER update_orders_updated_at
     BEFORE UPDATE ON orders
     FOR EACH ROW
diff --git a/supabase/migrations/004_brand_tables.sql b/supabase/migrations/004_brand_tables.sql
index bfa4a1aa..bdf2b77d 100644
--- a/supabase/migrations/004_brand_tables.sql
+++ b/supabase/migrations/004_brand_tables.sql
@@ -18,8 +18,8 @@ CREATE TABLE IF NOT EXISTS brands (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_brands_slug ON brands(slug);
-CREATE INDEX idx_brands_onboarded ON brands(onboarded);
+CREATE INDEX IF NOT EXISTS idx_brands_slug ON brands(slug);
+CREATE INDEX IF NOT EXISTS idx_brands_onboarded ON brands(onboarded);
 
 -- ============================================================================
 -- BRAND USERS (for multi-user brand accounts)
@@ -34,8 +34,8 @@ CREATE TABLE IF NOT EXISTS brand_users (
     UNIQUE(brand_id, user_id)
 );
 
-CREATE INDEX idx_brand_users_brand_id ON brand_users(brand_id);
-CREATE INDEX idx_brand_users_user_id ON brand_users(user_id);
+CREATE INDEX IF NOT EXISTS idx_brand_users_brand_id ON brand_users(brand_id);
+CREATE INDEX IF NOT EXISTS idx_brand_users_user_id ON brand_users(user_id);
 
 -- ============================================================================
 -- PRODUCTS
@@ -55,9 +55,9 @@ CREATE TABLE IF NOT EXISTS products (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_products_brand_id ON products(brand_id);
-CREATE INDEX idx_products_category ON products(category);
-CREATE INDEX idx_products_active ON products(active);
+CREATE INDEX IF NOT EXISTS idx_products_brand_id ON products(brand_id);
+CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
+CREATE INDEX IF NOT EXISTS idx_products_active ON products(active);
 
 -- ============================================================================
 -- PRODUCT VARIANTS
@@ -76,9 +76,9 @@ CREATE TABLE IF NOT EXISTS product_variants (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_product_variants_product_id ON product_variants(product_id);
-CREATE INDEX idx_product_variants_sku ON product_variants(sku);
-CREATE INDEX idx_product_variants_stock ON product_variants(stock);
+CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants(product_id);
+CREATE INDEX IF NOT EXISTS idx_product_variants_sku ON product_variants(sku);
+CREATE INDEX IF NOT EXISTS idx_product_variants_stock ON product_variants(stock);
 
 -- ============================================================================
 -- SIZE CHARTS
@@ -95,8 +95,8 @@ CREATE TABLE IF NOT EXISTS size_charts (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_size_charts_brand_id ON size_charts(brand_id);
-CREATE INDEX idx_size_charts_category ON size_charts(category);
+CREATE INDEX IF NOT EXISTS idx_size_charts_brand_id ON size_charts(brand_id);
+CREATE INDEX IF NOT EXISTS idx_size_charts_category ON size_charts(category);
 
 -- ============================================================================
 -- FIT MAPS (brand-specific fit rules)
@@ -112,18 +112,20 @@ CREATE TABLE IF NOT EXISTS fit_maps (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_fit_maps_brand_id ON fit_maps(brand_id);
-CREATE INDEX idx_fit_maps_category ON fit_maps(category);
+CREATE INDEX IF NOT EXISTS idx_fit_maps_brand_id ON fit_maps(brand_id);
+CREATE INDEX IF NOT EXISTS idx_fit_maps_category ON fit_maps(category);
 
 -- ============================================================================
 -- Add foreign key constraints to products
 -- ============================================================================
 
 ALTER TABLE products
+    DROP CONSTRAINT IF EXISTS fk_products_size_chart,
     ADD CONSTRAINT fk_products_size_chart
     FOREIGN KEY (size_chart_id) REFERENCES size_charts(id) ON DELETE SET NULL;
 
 ALTER TABLE products
+    DROP CONSTRAINT IF EXISTS fk_products_fit_map,
     ADD CONSTRAINT fk_products_fit_map
     FOREIGN KEY (fit_map_id) REFERENCES fit_maps(id) ON DELETE SET NULL;
 
@@ -143,8 +145,8 @@ CREATE TABLE IF NOT EXISTS catalog_import_jobs (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_catalog_import_jobs_brand_id ON catalog_import_jobs(brand_id);
-CREATE INDEX idx_catalog_import_jobs_status ON catalog_import_jobs(status);
+CREATE INDEX IF NOT EXISTS idx_catalog_import_jobs_brand_id ON catalog_import_jobs(brand_id);
+CREATE INDEX IF NOT EXISTS idx_catalog_import_jobs_status ON catalog_import_jobs(status);
 
 -- ============================================================================
 -- ROW-LEVEL SECURITY (RLS) POLICIES
@@ -160,65 +162,79 @@ ALTER TABLE fit_maps ENABLE ROW LEVEL SECURITY;
 ALTER TABLE catalog_import_jobs ENABLE ROW LEVEL SECURITY;
 
 -- Brands: Users can view all brands, but only brand users can modify
+DROP POLICY IF EXISTS "Anyone can view brands" ON brands;
 CREATE POLICY "Anyone can view brands"
     ON brands FOR SELECT
     USING (true);
 
+DROP POLICY IF EXISTS "Brand users can update their brands" ON brands;
 CREATE POLICY "Brand users can update their brands"
     ON brands FOR UPDATE
     USING (id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
 
 -- Brand Users: Users can view their own brand memberships
+DROP POLICY IF EXISTS "Users can view their brand memberships" ON brand_users;
 CREATE POLICY "Users can view their brand memberships"
     ON brand_users FOR SELECT
     USING (user_id = auth.uid());
 
 -- Products: Anyone can view active products, brand users can manage
+DROP POLICY IF EXISTS "Anyone can view active products" ON products;
 CREATE POLICY "Anyone can view active products"
     ON products FOR SELECT
     USING (active = true OR brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
 
+DROP POLICY IF EXISTS "Brand users can insert products" ON products;
 CREATE POLICY "Brand users can insert products"
     ON products FOR INSERT
     WITH CHECK (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
 
+DROP POLICY IF EXISTS "Brand users can update products" ON products;
 CREATE POLICY "Brand users can update products"
     ON products FOR UPDATE
     USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
 
+DROP POLICY IF EXISTS "Brand users can delete products" ON products;
 CREATE POLICY "Brand users can delete products"
     ON products FOR DELETE
     USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
 
 -- Product Variants: Anyone can view variants of active products
+DROP POLICY IF EXISTS "Anyone can view product variants" ON product_variants;
 CREATE POLICY "Anyone can view product variants"
     ON product_variants FOR SELECT
     USING (product_id IN (SELECT id FROM products WHERE active = true)
            OR product_id IN (SELECT id FROM products WHERE brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid())));
 
+DROP POLICY IF EXISTS "Brand users can manage product variants" ON product_variants;
 CREATE POLICY "Brand users can manage product variants"
     ON product_variants FOR ALL
     USING (product_id IN (SELECT id FROM products WHERE brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid())));
 
 -- Size Charts: Brand users can manage their size charts
+DROP POLICY IF EXISTS "Brand users can view their size charts" ON size_charts;
 CREATE POLICY "Brand users can view their size charts"
     ON size_charts FOR SELECT
     USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
 
+DROP POLICY IF EXISTS "Brand users can manage size charts" ON size_charts;
 CREATE POLICY "Brand users can manage size charts"
     ON size_charts FOR ALL
     USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
 
 -- Fit Maps: Brand users can manage their fit maps
+DROP POLICY IF EXISTS "Brand users can view their fit maps" ON fit_maps;
 CREATE POLICY "Brand users can view their fit maps"
     ON fit_maps FOR SELECT
     USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
 
+DROP POLICY IF EXISTS "Brand users can manage fit maps" ON fit_maps;
 CREATE POLICY "Brand users can manage fit maps"
     ON fit_maps FOR ALL
     USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
 
 -- Catalog Import Jobs: Brand users can view their import jobs
+DROP POLICY IF EXISTS "Brand users can view their import jobs" ON catalog_import_jobs;
 CREATE POLICY "Brand users can view their import jobs"
     ON catalog_import_jobs FOR SELECT
     USING (brand_id IN (SELECT brand_id FROM brand_users WHERE user_id = auth.uid()));
@@ -228,31 +244,37 @@ CREATE POLICY "Brand users can view their import jobs"
 -- ============================================================================
 
 -- Triggers for updated_at
+DROP TRIGGER IF EXISTS update_brands_updated_at ON brands;
 CREATE TRIGGER update_brands_updated_at
     BEFORE UPDATE ON brands
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_products_updated_at ON products;
 CREATE TRIGGER update_products_updated_at
     BEFORE UPDATE ON products
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_product_variants_updated_at ON product_variants;
 CREATE TRIGGER update_product_variants_updated_at
     BEFORE UPDATE ON product_variants
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_size_charts_updated_at ON size_charts;
 CREATE TRIGGER update_size_charts_updated_at
     BEFORE UPDATE ON size_charts
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_fit_maps_updated_at ON fit_maps;
 CREATE TRIGGER update_fit_maps_updated_at
     BEFORE UPDATE ON fit_maps
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_catalog_import_jobs_updated_at ON catalog_import_jobs;
 CREATE TRIGGER update_catalog_import_jobs_updated_at
     BEFORE UPDATE ON catalog_import_jobs
     FOR EACH ROW
diff --git a/supabase/migrations/005_referral_tables.sql b/supabase/migrations/005_referral_tables.sql
index c5eff865..e9da6631 100644
--- a/supabase/migrations/005_referral_tables.sql
+++ b/supabase/migrations/005_referral_tables.sql
@@ -19,10 +19,10 @@ CREATE TABLE IF NOT EXISTS referrals (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_referrals_rid ON referrals(rid);
-CREATE INDEX idx_referrals_referrer_id ON referrals(referrer_id);
-CREATE INDEX idx_referrals_status ON referrals(status);
-CREATE INDEX idx_referrals_created_at ON referrals(created_at DESC);
+CREATE INDEX IF NOT EXISTS idx_referrals_rid ON referrals(rid);
+CREATE INDEX IF NOT EXISTS idx_referrals_referrer_id ON referrals(referrer_id);
+CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);
+CREATE INDEX IF NOT EXISTS idx_referrals_created_at ON referrals(created_at DESC);
 
 -- ============================================================================
 -- REFERRAL EVENTS
@@ -40,12 +40,12 @@ CREATE TABLE IF NOT EXISTS referral_events (
     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_referral_events_referral_id ON referral_events(referral_id);
-CREATE INDEX idx_referral_events_event_type ON referral_events(event_type);
-CREATE INDEX idx_referral_events_user_id ON referral_events(user_id);
-CREATE INDEX idx_referral_events_order_id ON referral_events(order_id);
-CREATE INDEX idx_referral_events_attributed ON referral_events(attributed);
-CREATE INDEX idx_referral_events_created_at ON referral_events(created_at DESC);
+CREATE INDEX IF NOT EXISTS idx_referral_events_referral_id ON referral_events(referral_id);
+CREATE INDEX IF NOT EXISTS idx_referral_events_event_type ON referral_events(event_type);
+CREATE INDEX IF NOT EXISTS idx_referral_events_user_id ON referral_events(user_id);
+CREATE INDEX IF NOT EXISTS idx_referral_events_order_id ON referral_events(order_id);
+CREATE INDEX IF NOT EXISTS idx_referral_events_attributed ON referral_events(attributed);
+CREATE INDEX IF NOT EXISTS idx_referral_events_created_at ON referral_events(created_at DESC);
 
 -- ============================================================================
 -- REFERRAL REWARDS
@@ -66,11 +66,11 @@ CREATE TABLE IF NOT EXISTS referral_rewards (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_referral_rewards_referral_id ON referral_rewards(referral_id);
-CREATE INDEX idx_referral_rewards_referrer_id ON referral_rewards(referrer_id);
-CREATE INDEX idx_referral_rewards_order_id ON referral_rewards(order_id);
-CREATE INDEX idx_referral_rewards_status ON referral_rewards(status);
-CREATE INDEX idx_referral_rewards_created_at ON referral_rewards(created_at DESC);
+CREATE INDEX IF NOT EXISTS idx_referral_rewards_referral_id ON referral_rewards(referral_id);
+CREATE INDEX IF NOT EXISTS idx_referral_rewards_referrer_id ON referral_rewards(referrer_id);
+CREATE INDEX IF NOT EXISTS idx_referral_rewards_order_id ON referral_rewards(order_id);
+CREATE INDEX IF NOT EXISTS idx_referral_rewards_status ON referral_rewards(status);
+CREATE INDEX IF NOT EXISTS idx_referral_rewards_created_at ON referral_rewards(created_at DESC);
 
 -- ============================================================================
 -- REFERRAL FRAUD RULES
@@ -86,13 +86,14 @@ CREATE TABLE IF NOT EXISTS referral_fraud_rules (
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
 );
 
-CREATE INDEX idx_referral_fraud_rules_enabled ON referral_fraud_rules(enabled);
+CREATE INDEX IF NOT EXISTS idx_referral_fraud_rules_enabled ON referral_fraud_rules(enabled);
 
 -- ============================================================================
 -- Add foreign key to orders table for referral tracking
 -- ============================================================================
 
 ALTER TABLE orders
+    DROP CONSTRAINT IF EXISTS fk_orders_referral,
     ADD CONSTRAINT fk_orders_referral
     FOREIGN KEY (referral_id) REFERENCES referrals(id) ON DELETE SET NULL;
 
@@ -107,24 +108,29 @@ ALTER TABLE referral_rewards ENABLE ROW LEVEL SECURITY;
 ALTER TABLE referral_fraud_rules ENABLE ROW LEVEL SECURITY;
 
 -- Referrals: Users can view and manage their own referrals
+DROP POLICY IF EXISTS "Users can view their own referrals" ON referrals;
 CREATE POLICY "Users can view their own referrals"
     ON referrals FOR SELECT
     USING (auth.uid() = referrer_id);
 
+DROP POLICY IF EXISTS "Users can insert their own referrals" ON referrals;
 CREATE POLICY "Users can insert their own referrals"
     ON referrals FOR INSERT
     WITH CHECK (auth.uid() = referrer_id);
 
+DROP POLICY IF EXISTS "Users can update their own referrals" ON referrals;
 CREATE POLICY "Users can update their own referrals"
     ON referrals FOR UPDATE
     USING (auth.uid() = referrer_id);
 
 -- Referral Events: Users can view events for their referrals
+DROP POLICY IF EXISTS "Users can view events for their referrals" ON referral_events;
 CREATE POLICY "Users can view events for their referrals"
     ON referral_events FOR SELECT
     USING (referral_id IN (SELECT id FROM referrals WHERE referrer_id = auth.uid()));
 
 -- Referral Rewards: Users can view their own rewards
+DROP POLICY IF EXISTS "Users can view their own rewards" ON referral_rewards;
 CREATE POLICY "Users can view their own rewards"
     ON referral_rewards FOR SELECT
     USING (auth.uid() = referrer_id OR auth.uid() = referee_id);
@@ -137,16 +143,19 @@ CREATE POLICY "Users can view their own rewards"
 -- ============================================================================
 
 -- Triggers for updated_at
+DROP TRIGGER IF EXISTS update_referrals_updated_at ON referrals;
 CREATE TRIGGER update_referrals_updated_at
     BEFORE UPDATE ON referrals
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_referral_rewards_updated_at ON referral_rewards;
 CREATE TRIGGER update_referral_rewards_updated_at
     BEFORE UPDATE ON referral_rewards
     FOR EACH ROW
     EXECUTE FUNCTION update_updated_at_column();
 
+DROP TRIGGER IF EXISTS update_referral_fraud_rules_updated_at ON referral_fraud_rules;
 CREATE TRIGGER update_referral_fraud_rules_updated_at
     BEFORE UPDATE ON referral_fraud_rules
     FOR EACH ROW
diff --git a/supabase/migrations/006_auth_enhancements.sql b/supabase/migrations/006_auth_enhancements.sql
index 231ccf08..22cce724 100644
--- a/supabase/migrations/006_auth_enhancements.sql
+++ b/supabase/migrations/006_auth_enhancements.sql
@@ -1,6 +1,24 @@
 -- Auth Enhancements Migration
 -- Adds refresh tokens, failed attempts tracking, and user roles
 
+DO $$
+BEGIN
+  IF NOT EXISTS (
+    SELECT 1 FROM information_schema.tables
+    WHERE table_schema = 'public' AND table_name = 'users'
+  ) THEN
+    EXECUTE $DDL$
+      CREATE TABLE users (
+        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
+        email TEXT UNIQUE,
+        password_hash TEXT,
+        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
+      )
+    $DDL$;
+  END IF;
+END
+$$;
+
 -- Add failed_attempts column to users table
 ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_attempts INTEGER DEFAULT 0;
 ALTER TABLE users ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'shopper';
@@ -49,10 +67,12 @@ $$ LANGUAGE plpgsql;
 -- RLS Policies for refresh_tokens
 ALTER TABLE refresh_tokens ENABLE ROW LEVEL SECURITY;
 
+DROP POLICY IF EXISTS "Users can view their own refresh tokens" ON refresh_tokens;
 CREATE POLICY "Users can view their own refresh tokens"
   ON refresh_tokens FOR SELECT
   USING (auth.uid() = user_id);
 
+DROP POLICY IF EXISTS "Users can delete their own refresh tokens" ON refresh_tokens;
 CREATE POLICY "Users can delete their own refresh tokens"
   ON refresh_tokens FOR DELETE
   USING (auth.uid() = user_id);
diff --git a/supabase/migrations/007_referrals_and_brand_admins.sql b/supabase/migrations/007_referrals_and_brand_admins.sql
index e4512b16..e4f21b8d 100644
--- a/supabase/migrations/007_referrals_and_brand_admins.sql
+++ b/supabase/migrations/007_referrals_and_brand_admins.sql
@@ -5,7 +5,7 @@
 CREATE TABLE IF NOT EXISTS referrals (
   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
   rid TEXT NOT NULL UNIQUE,
-  referrer_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
+  referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
   active BOOLEAN DEFAULT TRUE,
   total_clicks INTEGER DEFAULT 0,
   total_signups INTEGER DEFAULT 0,
@@ -50,12 +50,6 @@ CREATE TABLE IF NOT EXISTS brand_admins (
 );
 
 -- Create indexes
-CREATE INDEX IF NOT EXISTS idx_referrals_rid ON referrals(rid);
-CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_user_id);
-CREATE INDEX IF NOT EXISTS idx_referral_events_rid ON referral_events(rid);
-CREATE INDEX IF NOT EXISTS idx_referral_events_user ON referral_events(user_id);
-CREATE INDEX IF NOT EXISTS idx_referral_events_order ON referral_events(order_id);
-CREATE INDEX IF NOT EXISTS idx_referral_rewards_user ON referral_rewards(user_id);
 CREATE INDEX IF NOT EXISTS idx_brand_admins_brand ON brand_admins(brand_id);
 CREATE INDEX IF NOT EXISTS idx_brand_admins_user ON brand_admins(user_id);
 
@@ -90,22 +84,8 @@ ALTER TABLE referral_events ENABLE ROW LEVEL SECURITY;
 ALTER TABLE referral_rewards ENABLE ROW LEVEL SECURITY;
 ALTER TABLE brand_admins ENABLE ROW LEVEL SECURITY;
 
--- Users can view their own referrals
-CREATE POLICY "Users can view their own referrals"
-  ON referrals FOR SELECT
-  USING (auth.uid() = referrer_user_id);
-
--- Users can create referrals
-CREATE POLICY "Users can create referrals"
-  ON referrals FOR INSERT
-  WITH CHECK (auth.uid() = referrer_user_id);
-
--- Users can view their own referral rewards
-CREATE POLICY "Users can view their own referral rewards"
-  ON referral_rewards FOR SELECT
-  USING (auth.uid() = user_id);
-
 -- Brand admins can view their brand
+DROP POLICY IF EXISTS "Brand admins can view their brand association" ON brand_admins;
 CREATE POLICY "Brand admins can view their brand association"
   ON brand_admins FOR SELECT
   USING (auth.uid() = user_id);
```
