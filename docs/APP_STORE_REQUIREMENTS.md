# iOS App Store Publication Requirements

## Critical Issues Requiring Resolution

This document identifies issues in the mochiwallet-ios codebase that may cause Apple App Store rejection or require resolution before submission.

---

## 🔴 CRITICAL (Will Cause Rejection)

### 1. Missing Privacy Manifest File (PrivacyInfo.xcprivacy)
**Impact**: App Store rejection since Spring 2024

Apple requires all apps to include a Privacy Manifest file (`PrivacyInfo.xcprivacy`) that declares:
- Data collected by the app
- Required reason APIs used (like UserDefaults/localStorage)
- Third-party SDK privacy information

**The app uses:**
- `localStorage` (via Chrome storage polyfills) - requires NSPrivacyAccessedAPIType declaration
- Device information collection (UIDevice) - requires privacy disclosure

**Fix Required**: Create `PrivacyInfo.xcprivacy` file declaring privacy practices.

---

### 2. Missing App Icons
**Impact**: App Store rejection

The `AppIcon.appiconset/Contents.json` references a 1024x1024 icon but **no actual image file exists** in the folder. The App Store requires:
- 1024x1024 App Store icon (mandatory)
- Various device-specific sizes for iOS 15+

**Asset Available**: The Android project contains `assets/mcm-playstore-icon-512.png` which can be scaled up to 1024x1024 for the App Store icon.

**Fix Required**: 
1. Create a 1024x1024 PNG image (can scale from existing 512px Android icon or create new)
2. Name it `AppIcon.png` (or similar)
3. Add to `ios/MochiWallet/Assets.xcassets/AppIcon.appiconset/`
4. Update Contents.json to reference the filename:
```json
{
  "images" : [
    {
      "filename" : "AppIcon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

---

### 3. Unused Camera Permission Declaration
**Impact**: Potential rejection under App Store Review Guideline 5.1.1

`Info.plist` declares `NSCameraUsageDescription` but the app has **no camera functionality implemented**. Apple rejects apps that request permissions they don't actually use.

**Fix Required**: Either:
- Remove `NSCameraUsageDescription` from Info.plist (recommended)
- OR implement QR code scanning functionality

---

### 4. exit(0) Termination Method
**Impact**: Potential rejection under App Store Review Guideline 4.0

The code in `ViewController.swift` line 218 uses `exit(0)` to terminate the app:
```swift
alert.addAction(UIAlertAction(title: "Exit", style: .destructive) { _ in
    exit(0)
})
```

Apple explicitly discourages programmatic app termination. iOS apps should let users exit via the home gesture/button.

**Fix Required**: Remove the exit confirmation dialog or change behavior to minimize to background.

---

## 🟠 HIGH PRIORITY (May Cause Rejection)

### 5. SSL Certificate Validation is Too Permissive
**Impact**: Security review failure

The current SSL handling in `ViewController.swift` always accepts server certificates:
```swift
func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    if let serverTrust = challenge.protectionSpace.serverTrust {
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)  // Always accepts!
    }
    ...
}
```

This bypasses proper certificate validation. For a financial/wallet app, Apple may flag this during security review.

**Fix Required**: Use default system certificate validation or implement proper certificate pinning.

---

### 6. Deprecated API Usage
**Impact**: May cause issues with future iOS versions

```swift
if #available(iOS 16.4, *) {
    // Modern iOS handles this through loadFileURL's allowingReadAccessTo parameter
} else {
    configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
}
```

Using `setValue:forKey:` for WebKit preferences is undocumented/deprecated and may cause rejection.

**Fix Required**: Use only documented WKWebView APIs or accept iOS 16.4+ minimum deployment.

---

### 7. App Transport Security Configuration
**Impact**: May require justification during review

The app uses:
```xml
<key>NSAllowsArbitraryLoadsInWebContent</key>
<true/>
```

While this is acceptable for WebView-based apps, Apple may ask for justification. Document that this is required for blockchain API communication.

---

## 🟡 MEDIUM PRIORITY (Best Practices)

### 8. Missing App Privacy Policy URL
**Impact**: Requirement for App Store Connect

The `legal-links.js` patch adds Terms of Service and Privacy Policy links that point to:
- `https://mochimo.org/mobile-wallet-terms`
- `https://mochimo.org/mobile-wallet-privacy`

**Verify**: These URLs must be live and accessible before App Store submission. App Store Connect requires a Privacy Policy URL field.

---

### 9. Missing Entitlements File
**Impact**: May limit functionality or cause signing issues

No `.entitlements` file exists. For a wallet app, you may need:
- Keychain sharing entitlements (if sharing data between apps)
- App Groups (if using extensions)

**Review**: Determine if any entitlements are needed for wallet functionality.

---

### 10. Version Numbers Need Update
**Impact**: App Store requires incremental versions

Current settings:
```
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
```

These should be updated before each App Store submission and should match the Android version scheme for consistency.

---

### 11. Bundle Identifier Placeholder
**Impact**: Must be unique before submission

```
PRODUCT_BUNDLE_IDENTIFIER = com.mochimo.wallet;
```

Verify this bundle ID is:
- Registered in Apple Developer portal
- Not conflicting with existing apps
- Consistent with your organization

---

## 🟢 ALREADY COMPLIANT

The following items are correctly configured:

✅ `ITSAppUsesNonExemptEncryption = false` - Correctly declared (wallet uses standard iOS crypto)
✅ `UIUserInterfaceStyle = Dark` - Properly set
✅ External URL handling - Opens in Safari (matches Android security fix)
✅ `UIRequiresFullScreen = YES` - Properly configured
✅ Safe area handling via CSS - Properly implemented
✅ Terms of Service and Privacy Policy links - Added via patches
✅ Import from Backup / MCM hidden - File APIs not available on mobile

---

## Required Actions Summary

### Must Fix Before Submission:
1. ✅ Create `PrivacyInfo.xcprivacy` privacy manifest - **DONE**
2. ✅ Add app icon images (1024x1024 minimum) - **DONE**
3. ✅ Remove `NSCameraUsageDescription` from Info.plist - **DONE**
4. ✅ Remove or modify `exit(0)` app termination - **DONE** (shows informational dialog)
5. ✅ Fix SSL certificate validation - **DONE** (uses SecTrustEvaluateWithError)
6. ✅ Deprecated WebKit API - **ACCEPTABLE** (version-gated fallback for iOS 15.x-16.3)

### Should Fix:
7. ✅ Verify Privacy Policy URLs are live - **DONE** (verified accessible)
8. ✅ Review entitlements needs - **NOT REQUIRED** (standard WebView app)
9. ✅ Update version numbers - **DONE** (0.0.18)
10. ⬜ Verify bundle identifier registration

---

## References

- [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy Manifest Requirements](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [App Store Connect Requirements](https://developer.apple.com/help/app-store-connect/)

---

**Last Updated**: January 14, 2026
