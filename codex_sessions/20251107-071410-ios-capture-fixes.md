# ios capture fixes

- Timestamp: 2025-11-07 07:14:10 PST
- Branch: feature/web-hotfix
- Commit: 17179a16
- Tags: ios, backend, supabase

## Notes
Hooked CaptureFlowViewModel into FITWIN_API_URL/FITWIN_API_KEY from Info.plist so device builds point at the configured backend.
Restored FitTwinAppTests target + shared scheme so xcodebuild test works on device.
Made Supabase migrations 001-007 idempotent and added uuid-ossp extension.

## Git Status
```text
M mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate
?? codex_sessions/20251107-051143-dev-stack-port-guard.md
?? dev-stack.log
?? dev-stack.pid
?? screenshots_local/
?? tmp-postgres/
```

## Git Diff
```diff
diff --git a/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate b/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate
index 57867c34..47e172ad 100644
Binary files a/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate and b/mobile/ios/FitTwinApp/FitTwinApp.xcodeproj/project.xcworkspace/xcuserdata/laura.xcuserdatad/UserInterfaceState.xcuserstate differ
```
