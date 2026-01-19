# Technical Documentation
## mochiwallet-apple Maintainer Guide

**Audience**: Repository maintainer  
**Purpose**: Understand the architecture, critical components, and maintenance workflows for the iOS/macOS wrapper

---

## Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [Critical Components](#2-critical-components)
3. [Maintenance Workflows](#3-maintenance-workflows)
4. [iOS-Specific Considerations](#4-ios-specific-considerations)
5. [File Reference](#5-file-reference)
6. [Version Compatibility](#6-version-compatibility)
7. [Security Considerations](#7-security-considerations)
8. [Troubleshooting Guide](#8-troubleshooting-guide)
9. [Changelog](#9-changelog)

---

## 1. Architecture Overview

### What This Repository Does

This repository wraps the Mochimo wallet Chrome extension as an iOS application. It does **not** contain the wallet logic itself—that lives in the upstream `adequatesystems/mochiwallet` repository.

**Core Strategy**:
- Use git submodule to track the upstream extension
- Apply minimal iOS-specific patches
- Bundle extension in WKWebView
- Automate the entire build process

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      iOS App (MochiWallet)                      │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  AppDelegate    │  │  SceneDelegate  │  │ViewController   │  │
│  │  (Lifecycle)    │  │  (Scene mgmt)   │  │ (WKWebView)     │  │
│  └─────────────────┘  └─────────────────┘  └────────┬────────┘  │
│                                                      │          │
│  ┌───────────────────────────────────────────────────▼────────┐ │
│  │                      WKWebView                              │ │
│  │  ┌─────────────────────────────────────────────────────┐   │ │
│  │  │              Web Extension (from submodule)          │   │ │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌────────┐  │   │ │
│  │  │  │index.html│  │  CSS    │  │   JS    │  │ Assets │  │   │ │
│  │  │  └─────────┘  └─────────┘  └─────────┘  └────────┘  │   │ │
│  │  └─────────────────────────────────────────────────────┘   │ │
│  │                           │                                 │ │
│  │  ┌────────────────────────▼─────────────────────────────┐  │ │
│  │  │                  iOS Patches Layer                    │  │ │
│  │  │  ┌────────────┐  ┌──────────┐  ┌─────────────────┐   │  │ │
│  │  │  │polyfills.js│  │ios-ui.css│  │ hide-*.js files │   │  │ │
│  │  │  │(Chrome API)│  │(layout)  │  │ (UI tweaks)     │   │  │ │
│  │  │  └────────────┘  └──────────┘  └─────────────────┘   │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│  ┌───────────────────────────▼───────────────────────────────┐  │
│  │              JavaScript Bridge (WKScriptMessageHandler)    │  │
│  │  • iOSBridge: Device info, haptics, exit                  │  │
│  │  • log: Console logging to native                          │  │
│  │  • toast: Native toast messages                            │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    External Services                            │
│  • Mochimo blockchain network (via extension's API client)      │
│  • localStorage (persisted wallet data)                         │
└─────────────────────────────────────────────────────────────────┘
```

### Repository Structure

```
mochiwallet-apple/                # This repo (iOS wrapper only)
├── mochiwallet/                  # Git submodule → adequatesystems/mochiwallet
├── ios/                          # iOS project (Xcode, Swift)
│   ├── MochiWallet/
│   │   ├── Resources/            # Built extension copied here at build time
│   │   ├── ViewController.swift  # WKWebView configuration
│   │   ├── AppDelegate.swift     # Application lifecycle
│   │   ├── SceneDelegate.swift   # Scene lifecycle
│   │   ├── Info.plist            # App configuration
│   │   ├── Assets.xcassets/      # App icons and images
│   │   └── LaunchScreen.storyboard
│   └── MochiWallet.xcodeproj     # Xcode project
├── patches/
│   ├── polyfills.js              # Chrome API polyfills + Buffer for WKWebView (CRITICAL)
│   ├── ios-ui.css                # Full-width layout for mobile screens
│   ├── mobile-ui-panel-button.js # Hides panel toggle button in header
│   ├── mobile-ui-mcm-import.js   # Hides "Import MCM File" option
│   ├── mobile-ui-export.js       # Hides Backup/Export section in Settings
│   └── vite.config.patch         # Documents the relative path patch (informational)
├── build.sh                      # Automated build orchestration (macOS/Linux)
├── .gitmodules                   # Submodule configuration
└── docs/
    └── TECHNICAL_DOCUMENTATION.md    # This file
```

### Why This Architecture?

1. **Separation of Concerns**: Wallet development happens upstream; iOS wrapper is minimal
2. **Maintainability**: Updates from upstream are a simple `git pull` in the submodule
3. **Single Source of Truth**: Extension code isn't duplicated or forked
4. **Automation**: One script handles the entire build pipeline

---

## 2. Critical Components

### 2.1 Git Submodule (`mochiwallet/`)

**File**: `.gitmodules`

```ini
[submodule "mochiwallet"]
    path = mochiwallet
    url = https://github.com/adequatesystems/mochiwallet.git
    branch = main
```

**Key Points**:
- The iOS repo tracks a specific commit of the extension
- Updates are manual and intentional (you control when to pull changes)
- After updating submodule, must commit the new pointer

**Common Operations**:
```bash
# Initial clone setup
git submodule init && git submodule update

# Update to latest upstream
cd mochiwallet && git pull origin main && cd ..

# Check current version
cd mochiwallet && git log -1 --oneline && cd ..
```

### 2.2 Build Script (`build.sh`)

**Purpose**: Orchestrates the entire build pipeline

**Seven Steps**:
1. ✅ Verify `mochiwallet/` submodule exists (auto-init/clone if missing)
2. ✅ Build extension: `cd mochiwallet && pnpm install && pnpm run build` (with git dependency workaround)
3. ✅ Patch `vite.config.ts` to set `base: './'` (required for WKWebView)
4. ✅ Copy `mochiwallet/dist/` → `ios/MochiWallet/Resources/`
5. ✅ Inject `patches/polyfills.js` and UI patches into resources
6. ✅ Fix `index.html`: remove `require('buffer')`, add polyfills script tag
7. ✅ Build iOS app: `xcodebuild -project MochiWallet.xcodeproj ...`

**Critical Patches Applied**:

| Patch | File Modified | Why Needed |
|-------|--------------|------------|
| `base: './'` | `mochiwallet/vite.config.ts` | WKWebView needs relative paths, not absolute (`/assets/`) |
| Fix asset paths | `ios/MochiWallet/Resources/index.html` | Convert `/assets/` to `./assets/` for WKWebView compatibility |
| Add polyfills | `ios/MochiWallet/Resources/index.html` | Chrome APIs don't exist in WKWebView |
| Remove `require('buffer')` | `ios/MochiWallet/Resources/index.html` | Node.js require() doesn't work in WKWebView |

**Build Options**:
```bash
./build.sh                         # Full build for simulator
./build.sh -s                      # Use existing mochiwallet/dist/
./build.sh -d                      # Build for physical device
./build.sh -r                      # Build Release configuration
./build.sh -c                      # Clean build from scratch
./build.sh -v                      # Verbose logging
./build.sh -h                      # Show help
```

### 2.2.1 Git Dependency Build Workaround

**Problem**: The upstream `mochiwallet` extension depends on git-hosted packages (`mochimo-wallet`, `mochimo-mesh-api-client`, `mochimo-wots`) that may fail to build during `pnpm install`. This happens because:

1. **pnpm 10.x blocks git dependencies** - Requires explicit `onlyBuiltDependencies` allowlist
2. **Upstream packages missing `onlyBuiltDependencies`** - The `mochimo-wallet` git package itself has nested git dependencies that lack this configuration
3. **TypeScript errors in upstream** - Type incompatibilities with `@types/node` v20+ cause `tsc` compilation to fail

**Automatic Workaround**: The build script (`build.sh`) handles this automatically:

1. Create a `pnpm-workspace.yaml` in the extension directory with proper `onlyBuiltDependencies`
2. Attempt normal `pnpm@8 install`
3. If `node_modules/mochimo-wallet/dist/` is missing, trigger manual build:
   - Re-install with `--ignore-scripts` to skip failed builds
   - Clone `mochimo-wallet` separately with correct `onlyBuiltDependencies` config
   - Run `npx vite build` (TypeScript errors shown but esbuild produces valid output)
   - Clone `mochimo-mesh-api-client` separately
   - Run `npx tsup src/index.ts --format cjs,esm --dts`
   - Copy pre-built `dist/` folders to the extension's `node_modules/`

**Why This Works**: While `tsc` (TypeScript compiler) fails on type errors, Vite uses esbuild internally which ignores type errors and produces valid JavaScript output.

**Upstream Fix**: This workaround will become unnecessary if/when the upstream `adequatesystems/mochimo-wallet` repository adds the `onlyBuiltDependencies` configuration to their `pnpm-workspace.yaml`.

### 2.3 Polyfills (`patches/polyfills.js`)

**Purpose**: Bridge the gap between Chrome extension APIs and iOS WKWebView

**Critical Features**:

1. **Buffer Polyfill with HEX Encoding**
   ```javascript
   Buffer.from("420000000e00000001000000", "hex")
   ```
   - Used by Mochimo WOTS+ address generation
   - Converts 24-character hex string → 12-byte array
   - **WITHOUT THIS**: "Invalid tag" error during account creation

2. **Chrome API Stubs**
   - `chrome.runtime.sendMessage()`
   - `chrome.storage.local.get/set()`
   - `chrome.tabs.create()`
   - Extension expects these APIs; WKWebView doesn't provide them
   - Polyfills provide compatible localStorage-based implementations

3. **iOS Bridge**
   - `window.iOSBridge.showToast()`
   - `window.iOSBridge.vibrate()`
   - `window.iOSBridge.getDeviceInfo()`
   - Communicates with native Swift code via `WKScriptMessageHandler`

**Debug Mode**:
The polyfills file includes a `POLYFILL_DEBUG` flag at the top:
```javascript
const POLYFILL_DEBUG = false; // Set to true for verbose logging
```
Set to `true` when troubleshooting Chrome API compatibility issues.

**Never Delete This File**: The wallet will not function without it.

### 2.4 WKWebView Configuration (`ViewController.swift`)

**Critical Settings**:

```swift
// Configure preferences
let preferences = WKWebpagePreferences()
preferences.allowsContentJavaScript = true
configuration.defaultWebpagePreferences = preferences

// Enable local storage (equivalent to Android's domStorageEnabled)
configuration.websiteDataStore = .default()

// File access is handled through loadFileURL's allowingReadAccessTo parameter
// The deprecated allowFileAccessFromFileURLs is only used as fallback for older iOS
```

**Why These Are Critical**:
- Chrome extensions have special privileges
- iOS WKWebView is sandboxed by default
- `allowFileAccessFromFileURLs` enables loading local assets
- Without these: CORS errors, blank screen

**JavaScript Bridge**:
The app uses `WKScriptMessageHandler` to enable communication between JavaScript and Swift:
```swift
contentController.add(self, name: "iOSBridge")
contentController.add(self, name: "log")
contentController.add(self, name: "toast")
```

**Error Handling**:
- `webView(_:didFailProvisionalNavigation:withError:)` - Displays user-friendly error page
- SSL certificate validation - Always validates certificates (security)

---

## 3. Maintenance Workflows

### 3.1 Updating from Upstream

```bash
# 1. Pull latest extension
cd mochiwallet
git fetch origin
git checkout main
git pull origin main
cd ..

# 2. Rebuild
./build.sh

# 3. Test thoroughly
# - Create new wallet
# - Import existing wallet
# - Send transaction

# 4. Commit new submodule pointer
git add mochiwallet
git commit -m "Update mochiwallet to $(cd mochiwallet && git rev-parse --short HEAD)"
```

### 3.2 Adding New Patches

1. Create patch file in `patches/`
2. Update `build.sh` to copy and inject the patch
3. Document in this file
4. Test with clean build

### 3.3 Debugging WKWebView Issues

**Enable Debug Logging**:
1. Edit `patches/polyfills.js`: Set `POLYFILL_DEBUG = true`
2. Rebuild: `./build.sh`
3. Open Safari → Develop → [Device/Simulator] → MochiWallet
4. View console logs in Safari Web Inspector

**Common Issues**:

| Symptom | Cause | Solution |
|---------|-------|----------|
| Blank screen | Asset paths wrong | Check `base: './'` in vite.config |
| "Invalid tag" error | Missing Buffer polyfill | Ensure polyfills.js is injected |
| Storage not persisting | localStorage quota | Check WKWebView configuration |
| Network errors | App Transport Security | Check Info.plist NSAppTransportSecurity |

---

## 4. iOS-Specific Considerations

### 4.1 Safe Area Handling

The app handles notched devices (iPhone X+) via CSS:
```css
padding-top: env(safe-area-inset-top);
padding-bottom: env(safe-area-inset-bottom);
```

### 4.2 Code Signing

- **Simulator**: No signing required
- **Device**: Requires Apple Developer account
- Configure in Xcode: Target → Signing & Capabilities

### 4.3 App Store Submission

Before submitting:
1. Set proper bundle identifier
2. Add app icons (all required sizes)
3. Configure App Transport Security properly
4. Test on physical devices
5. Create App Store screenshots

---

## 5. File Reference

| File | Purpose | Critical |
|------|---------|----------|
| `build.sh` | Main build script | CRITICAL |
| `ios/MochiWallet.xcodeproj/project.pbxproj` | Xcode project configuration | CRITICAL |
| `ios/MochiWallet/ViewController.swift` | WKWebView setup and configuration | CRITICAL |
| `ios/MochiWallet/AppDelegate.swift` | Application lifecycle | CRITICAL |
| `ios/MochiWallet/SceneDelegate.swift` | Scene lifecycle (iOS 13+) | CRITICAL |
| `ios/MochiWallet/Info.plist` | App configuration and permissions | CRITICAL |
| `patches/polyfills.js` | Chrome API polyfills + Buffer | CRITICAL |
| `patches/ios-ui.css` | Mobile-optimized CSS with safe areas | Optional |
| `patches/mobile-ui-panel-button.js` | Removes panel toggle button | Optional |
| `patches/mobile-ui-mcm-import.js` | Removes MCM file import option | Optional |
| `patches/mobile-ui-export.js` | Removes backup/export section | Optional |
| `patches/mobile-ui-main-screen.js` | Main screen: removes backup import, renames mnemonic | Optional |
| `patches/legal-links.js` | Adds Terms of Service and Privacy Policy links | Optional |
| `.gitmodules` | Submodule configuration | CRITICAL |
| `mochiwallet/` | Upstream extension (submodule) | CRITICAL |

---

## 6. Version Compatibility

| Component | Minimum Version | Recommended |
|-----------|----------------|-------------|
| **macOS** | 13.0 (Ventura) | 14.0+ (Sonoma) |
| iOS | 15.0 | 17.0+ |
| Xcode | 15.0 | 15.2+ |
| Swift | 5.0 | Latest |
| Node.js | 18.x | 20.x |
| pnpm | 8.x | 8.x |

### Platform Requirements

**⚠️ macOS Only**: This project requires macOS for development and building. Xcode and iOS Simulator are not available on Windows or Linux.

#### Alternative Options for Non-Mac Users

1. **Cloud macOS Services**
   - MacStadium: Professional cloud Mac hosting
   - MacinCloud: Pay-per-hour Mac access
   - AWS EC2 Mac instances: Enterprise option
   - GitHub Codespaces with macOS runner

2. **Contribution Workflow Without Mac**
   - Modify JavaScript patches in `patches/`
   - Update documentation
   - Test web extension in Chrome on your platform
   - Submit PR and let CI/CD verify iOS build
   - Maintainers test on actual devices

3. **Testing the Web Extension**
   ```bash
   # On Windows/Linux, you can test the upstream extension
   cd mochiwallet
   pnpm install
   pnpm run dev
   # Load unpacked extension in Chrome
   ```

---

## 7. Security Considerations

### 7.1 WKWebView Security

**Risks**:
- WKWebView runs JavaScript with access to local storage
- `allowFileAccessFromFileURLs` is enabled (required for local asset loading)
- JavaScript bridge exposes native functionality

**Mitigations**:
- Only load local files from the app bundle (no remote HTML)
- Validate all messages received via `WKScriptMessageHandler`
- External URLs open in Safari, not in the WKWebView
- SSL certificate validation is enforced

### 7.2 Data Storage

- Wallet data is stored in `localStorage` (sandboxed to app)
- Private keys are encrypted by the upstream extension
- No data is sent to external servers except blockchain API calls

### 7.3 JavaScript Injection

**Risk**: Injected scripts could be tampered with  
**Mitigation**: All patches are bundled at build time from the repository

### 7.4 Network Security

- `NSAllowsArbitraryLoadsInWebContent` is enabled for blockchain API calls
- Consider pinning certificates for production releases
- External links validated before opening

### 7.5 Recommendations

1. Regularly audit `polyfills.js` for security issues
2. Keep dependencies updated (upstream extension, Xcode)
3. Test on physical devices before releases
4. Consider implementing certificate pinning for API calls
5. Review App Transport Security settings periodically

---

## 8. Troubleshooting Guide

### Build Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| "Submodule not found" | Git submodule not initialized | `git submodule update --init --recursive` |
| "pnpm not found" | pnpm not installed | `npm install -g pnpm` or `corepack enable` |
| "xcodebuild failed" | Xcode not configured | `sudo xcode-select -s /Applications/Xcode.app` |
| Build hangs | Network issues | Check internet, try `pnpm install` manually |
| "Code signing error" | Missing provisioning | Configure team in Xcode for device builds |

### Runtime Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Blank/white screen | Asset paths wrong | Rebuild without `-s` flag, check vite.config patch |
| "Invalid tag" error | Buffer polyfill missing | Ensure polyfills.js is in Resources/ |
| Storage not persisting | WKWebView config | Check `websiteDataStore` is `.default()` |
| Network errors | ATS blocking | Check Info.plist `NSAppTransportSecurity` |
| Crypto errors | SubtleCrypto unavailable | iOS WKWebView should have this; check iOS version |

### Debugging Steps

1. **Enable verbose build**: `./build.sh --verbose`
2. **Enable JS debug logging**: Set `POLYFILL_DEBUG = true` in polyfills.js
3. **Safari Web Inspector**: Develop → [Device] → MochiWallet
4. **Check injected scripts**: Look for `[iOS Patch]` log messages
5. **Verify file structure**: Check `ios/MochiWallet/Resources/` contents

---

## 9. Changelog

### v0.0.18 (Current)
- **Added `mobile-ui-main-screen.js` patch**: Removes "Import from Backup" button and renames "Import from Mnemonic Phrase" to "Recover from Mnemonic Phrase" for clearer mobile UX
- **Added `legal-links.js` patch**: Displays Terms of Service and Privacy Policy links on Create Wallet and Welcome Back screens for App Store compliance
- **App Store compliance fixes**: Privacy manifest, SSL validation, exit behavior, unused permissions removed
- Updated build script to include new patches in injection order
- Updated documentation to match Android wallet feature parity
- Added git dependency build workaround documentation
- Added verbose (-v) and clean (-c) build options

### v1.1.0
- Enhanced ios-ui.css with dark mode and loading state support
- Added version markers to polyfills.js and build.sh
- Improved build script help output with examples
- Updated documentation to reflect current implementation

### v1.0.0 (Initial Release)
- WKWebView wrapper for mochiwallet Chrome extension
- Chrome API polyfills (runtime, storage, tabs)
- Buffer polyfill with hex/base64 encoding
- iOS-specific UI patches
- Automated build script
- GitHub Actions CI/CD
