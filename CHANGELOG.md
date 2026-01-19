# Changelog

All notable changes to the Mochimo Wallet iOS app will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.18-alpha.1] - 2026-01-19

### Added
- Initial public alpha release
- WKWebView-based wrapper with custom `app://` URL scheme handler
- Chrome extension API polyfills (Buffer, chrome.storage, chrome.runtime)
- Full-width responsive mobile UI with safe area support
- App Store compliance (privacy manifest, proper SSL validation)
- Automated CI/CD with Appetize.io integration for testing
- Release artifacts automatically attached to GitHub releases

### Architecture
- Upstream mochiwallet extension as git submodule
- Additive patches only (no upstream modifications required)
- Single build.sh script for complete build pipeline

### Mobile UI Patches
- `ios-ui.css` - Full-width layout with safe area support
- `mobile-ui-panel-button.js` - Hides panel toggle button
- `mobile-ui-mcm-import.js` - Hides MCM file import option
- `mobile-ui-export.js` - Hides backup/export section
- `mobile-ui-main-screen.js` - Main screen customizations
- `legal-links.js` - Terms of Service and Privacy Policy links
