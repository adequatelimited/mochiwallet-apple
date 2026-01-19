# Mochimo Wallet - Apple (iOS/macOS)

[![Build iOS App](https://github.com/adequatelimited/mochiwallet-apple/actions/workflows/build.yml/badge.svg)](https://github.com/adequatelimited/mochiwallet-apple/actions/workflows/build.yml)
![Version](https://img.shields.io/badge/version-0.0.18-blue)
![iOS](https://img.shields.io/badge/iOS-15.0%2B-green)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)

Apple (iOS/macOS) mobile app for the Mochimo cryptocurrency wallet, built as a WKWebView wrapper around the [mochiwallet](https://github.com/adequatesystems/mochiwallet) Chromium extension.

**This is a clean, separate repository** that pulls the upstream extension as a git submodule and contains only Apple platform-specific code.

> **Relationship to Upstream**: This repository does **not** contain wallet logic. All wallet functionality (UI, transaction handling, cryptography) lives in the upstream [mochiwallet](https://github.com/adequatesystems/mochiwallet) repository. This repo provides only the iOS/macOS wrapper, build scripts, and platform-specific patches needed to run the extension in WKWebView.

---

## 🚀 Quick Start

```bash
# Clone this repository
git clone https://github.com/adequatelimited/mochiwallet-apple.git
cd mochiwallet-apple

# Initialize the upstream extension submodule (build scripts will auto-init/clone if missing)
git submodule init
git submodule update

# Build the iOS app (macOS only)
./build.sh

# Or open in Xcode for development
open ios/MochiWallet.xcodeproj
```

**Build Complete** The app will be at: `ios/build/Build/Products/Debug-iphonesimulator/MochiWallet.app`

---

## 📋 Prerequisites

**⚠️ macOS Required**: iOS app development requires macOS. This project cannot be built on Windows or Linux. See [Windows/Linux Developers](#windowslinux-developers) below for alternatives.

Before building, install these on macOS:

| Component | Version | Download / Install |
|-----------|---------|-------------------|
| **Xcode** | 15.2+ | [Mac App Store](https://apps.apple.com/app/xcode/id497799835) |
| **Xcode Command Line Tools** | Latest | `xcode-select --install` |
| **Node.js** | v18+ | [Download](https://nodejs.org/) |
| **pnpm** | v8+ | [Download](https://pnpm.io/) or `corepack enable` (Node.js 16.13+) |
| **Git** | Latest | Included with Xcode CLT |

> **Note:** The CI uses Xcode 15.2 on macOS 14. For best compatibility, use matching versions locally.

> **Note:** Verify `pnpm` is in your PATH by running `pnpm --version`. If not found, ensure your Node.js/npm global bin directory is in PATH.

### Windows/Linux Developers

iOS app development requires macOS. If you don't have access to a Mac:

1. **Use CI/CD** - Push changes to GitHub; Actions builds on macOS runners automatically
2. **Cloud macOS** - Services like [MacStadium](https://www.macstadium.com/) or [MacinCloud](https://www.macincloud.com/)
3. **Test Web Extension** - The wallet runs in Chrome; only iOS-specific patches require macOS

### Initial Configuration

**1. Accept Xcode License (if not already done):**
```bash
sudo xcodebuild -license accept
```

**2. Select Xcode (if multiple versions installed):**
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

---

## 🏗️ Architecture

This repository uses a clean separation between extension code and iOS wrapper:

```
mochiwallet-apple/               # This repo (Apple platform-specific only)
│
├── .github/                     # GitHub Actions CI/CD workflows
│   └── workflows/build.yml      # Automated iOS build
│
├── mochiwallet/                 # Git submodule → upstream extension
│   ├── src/                     # Extension source code
│   └── dist/                    # Built by pnpm, copied to iOS
│
├── ios/                         # iOS/macOS project
│   ├── MochiWallet/
│   │   ├── Resources/           # Web app deployed here (build time)
│   │   ├── ViewController.swift # WKWebView configuration
│   │   ├── AppDelegate.swift    # Application lifecycle
│   │   └── Assets.xcassets/     # App icons and images
│   └── MochiWallet.xcodeproj    # Xcode project
│
├── patches/                     # iOS-specific patches
│   ├── polyfills.js             # Chrome API compatibility (CRITICAL)
│   ├── ios-ui.css               # Full-width layout for mobile screens
│   ├── mobile-ui-panel-button.js   # Removes panel toggle button
│   ├── mobile-ui-mcm-import.js     # Removes MCM file import option
│   ├── mobile-ui-export.js         # Removes backup/export section
│   ├── mobile-ui-main-screen.js # Main screen customizations
│   ├── legal-links.js           # Terms of Service and Privacy Policy
│   └── vite.config.patch        # Documents the relative path patch
│
├── docs/                        # Documentation
│   ├── TECHNICAL_DOCUMENTATION.md  # Complete technical guide
│   └── UI_PATCHES.md               # UI patch documentation
│
└── build.sh                     # Automated build script
```

### What's in This Repo vs Submodule

| This Repo (Apple-specific) | Submodule (Shared Extension) |
|---------------------------|------------------------------|
| iOS WKWebView wrapper | All wallet UI & logic |
| Build scripts | Extension source code |
| Apple patches (polyfills, CSS) | Transaction handling |
| Xcode project & configs | Blockchain API integration |
| App icons & splash screens | Cryptographic operations |

---

## 🔧 Build Process

The build script performs these steps:

1. **Check Submodule**: Verify/initialize `mochiwallet/` submodule
2. **Build Extension**: Run `pnpm install && pnpm run build` in extension (with git dependency workaround)
3. **Apply Patches**: Modify `vite.config.ts` for relative paths
4. **Copy Assets**: Move `dist/` to iOS resources
5. **Inject Polyfills**: Add Chrome API compatibility layer and mobile UI patches
6. **Fix index.html**: Remove Node.js-specific code, add polyfills
7. **Build iOS App**: Run `xcodebuild` to create the app

---

## 🎨 Mobile UI Patches

The build scripts automatically apply patches to adapt the browser extension UI for mobile devices. These patches remove UI elements that rely on browser APIs not available in iOS WKWebView:

| Patch | What It Does |
|-------|--------------|
| `ios-ui.css` | Optimizes layout for mobile screens with safe area support |
| `mobile-ui-panel-button.js` | Removes panel toggle button (browser panel API not available) |
| `mobile-ui-mcm-import.js` | Removes "Import MCM File" option (file picker API not available) |
| `mobile-ui-export.js` | Removes Backup section (file download API not available) |
| `mobile-ui-main-screen.js` | Removes "Import from Backup", renames mnemonic option |
| `legal-links.js` | Adds Terms of Service and Privacy Policy links |

These patches are optional but recommended. See [docs/UI_PATCHES.md](docs/UI_PATCHES.md) for details.

---

## 📱 Running on Device/Simulator

### Simulator
```bash
# Build and run on simulator
./build.sh

# Or use Xcode
open ios/MochiWallet.xcodeproj
# Select a simulator and press Cmd+R
```

### Physical Device
1. Open `ios/MochiWallet.xcodeproj` in Xcode
2. Select your Apple Developer Team in Signing & Capabilities
3. Connect your iOS device
4. Select your device and press Cmd+R

---

## 🍎 App Store Preparation

Before submitting to the App Store:

### Required Steps

1. **App Icons**: Add a 1024x1024 app icon to `Assets.xcassets/AppIcon.appiconset/`
2. **Bundle Identifier**: Update `com.mochimo.wallet` to your registered identifier
3. **Signing**: Configure your Apple Developer Team in Xcode
4. **Version**: Update `MARKETING_VERSION` in project settings
5. **Screenshots**: Capture screenshots for all required device sizes

### Already Configured ✅

- `ITSAppUsesNonExemptEncryption`: Set to `false` (wallet uses standard iOS crypto)
- `NSAppTransportSecurity`: Configured for blockchain API access
- Dark mode support via `UIUserInterfaceStyle`
- Privacy manifest (`PrivacyInfo.xcprivacy`) for App Store compliance

### Build for TestFlight

```bash
./build.sh -d -r  # Build Release for device
# Then archive in Xcode: Product → Archive
```

---

## 🐛 Troubleshooting

### Common Issues

**"Submodule not found"**
```bash
git submodule update --init --recursive
```

**"pnpm not found"**
```bash
# Install pnpm globally
npm install -g pnpm
# Or use corepack (Node.js 16.13+)
corepack enable
```

**"xcodebuild failed"**
- Ensure Xcode is installed and command line tools are selected
- Run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

**"Code signing error"**
- For simulator builds: No signing required
- For device builds: Configure your Apple Developer Team in Xcode

**"Invalid tag" or crypto errors**
- This usually means the polyfills weren't injected properly
- Try a clean rebuild: `./build.sh --clean`
- Check that `patches/polyfills.js` exists

**Build hangs at "Installing dependencies"**
- Network issues with npm/pnpm registries
- Try: `cd mochiwallet && pnpm install` manually to see detailed errors

**White/blank screen in app**
- Asset paths may be incorrect
- Check that `vite.config.ts` was patched to use `base: './'`
- Rebuild without `-s` flag: `./build.sh`

**"Module not found" errors**
- Dependencies may not have built correctly
- Run `./build.sh --clean` for a fresh build

### Debug Mode

For verbose build output:
```bash
./build.sh --verbose
```

To enable JavaScript debug logging, edit `patches/polyfills.js` and set:
```javascript
const POLYFILL_DEBUG = true;
```

Then use Safari Web Inspector (Develop → [Device] → MochiWallet) to view logs.

---

## 📄 License

See [LICENSE.md](LICENSE.md) for the Mochimo Cryptocurrency Engine License Agreement.

---

## 🔗 Related Repositories

- **[mochiwallet](https://github.com/adequatesystems/mochiwallet)** - Upstream Chrome extension
- **[mochiwallet-android](https://github.com/adequatesystems/mochiwallet-android)** - Android version
- **[mochimo](https://github.com/mochimodev/mochimo)** - Mochimo blockchain node
