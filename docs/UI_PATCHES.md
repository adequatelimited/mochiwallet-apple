# UI Patches Documentation
## iOS-Specific UI Modifications

This document describes the UI patches applied to the Mochimo wallet extension when running in the iOS WKWebView environment.

---

## Overview

The upstream Chrome extension is designed for browser popup windows with a fixed width. When running on iOS devices, several UI adjustments are needed for an optimal mobile experience.

---

## Patches

### 1. `ios-ui.css` - Full-Width Layout

**Purpose**: Make the wallet UI fill the device screen width.

**What It Does**:
- Removes fixed width constraints
- Sets `max-width: 100%` on root containers
- Adds safe area padding for notched devices (iPhone X+)
- Disables tap highlight color
- Enables smooth touch scrolling

**CSS Rules**:
```css
html, body {
  margin: 0;
  padding: 0 12px;
  width: 100%;
  max-width: 100%;
  padding-top: env(safe-area-inset-top);
  padding-bottom: env(safe-area-inset-bottom);
}

#root, #root > * {
  width: 100% !important;
  max-width: 100% !important;
}

/* Dark mode support */
@media (prefers-color-scheme: dark) {
  html, body {
    background-color: #1a1a2e;
    color: #ffffff;
  }
}

/* Force dark background to prevent white flash */
html {
  background-color: #1a1a2e;
}
```

---

### 2. `mobile-ui-panel-button.js` - Panel Toggle Removal

**Purpose**: Hide the "Expand to panel" button that doesn't work in WKWebView.

**What It Does**:
- Scans for buttons with Lucide PanelRight/PanelRightClose icons
- Hides matching buttons with `display: none`
- Uses MutationObserver to catch dynamically rendered buttons

**Technical Details**:
The extension has a button in the header that opens the wallet in a browser panel. This feature requires Chrome extension APIs that don't exist in WKWebView.

**Identification Logic**:
```javascript
// Look for buttons with SVG containing rect + line (Lucide panel icons)
// Skip buttons with 3 lines (menu icon)
if (rect && lines.length <= 2) {
  hide(btn);
}
```

---

### 3. `mobile-ui-mcm-import.js` - MCM File Import Removal

**Purpose**: Hide the "Import MCM File" option since file import isn't supported.

**What It Does**:
- Finds buttons/elements containing "Import MCM" text
- Hides them with `display: none`
- Observes DOM for dynamically added elements

**Why Hidden**:
MCM file import requires file system access that isn't available in the mobile app environment.

---

### 4. `mobile-ui-export.js` - Export/Backup Removal

**Purpose**: Hide wallet export functionality not suitable for mobile.

**What It Does**:
- Hides "Export Wallet" buttons
- Hides "Backup" section headings
- Hides export-related descriptions

**Why Hidden**:
File export/download functionality works differently on iOS and requires native implementation for proper handling.

---

### 5. `mobile-ui-main-screen.js` - Main Screen Customizations

**Purpose**: Customize the main/landing screen for mobile users.

**What It Does**:
- Removes "Import from Backup" button (file picker API not available on mobile)
- Renames "Import from Mnemonic Phrase" to "Recover from Mnemonic Phrase"

**Why These Changes**:
- "Import from Backup" requires file system access unavailable in mobile WebView
- "Recover from Mnemonic" is clearer language for mobile users than "Import from Mnemonic"

**Identification Logic**:
```javascript
// Text matching for backup import button
var BACKUP_TEXTS = ["import from backup", "import backup", "from backup"];

// Text replacement for mnemonic button
node.textContent.replace(/import from mnemonic/i, "Recover from Mnemonic");
```

---

### 6. `legal-links.js` - Terms of Service & Privacy Policy

**Purpose**: Display legal links on onboarding screens for App Store compliance.

**What It Does**:
- Adds "By using this App you accept the Terms of Service and Privacy Policy" message
- Shows only on Create Wallet and Welcome Back screens
- Links open in device browser (external URLs)

**Links**:
- Terms of Service: `https://mochimo.org/mobile-wallet-terms`
- Privacy Policy: `https://mochimo.org/mobile-wallet-privacy`

**Why Added**:
Apple App Store requires apps to display Terms of Service and Privacy Policy links. These are shown during onboarding when users first interact with the wallet.

---

## How Patches Are Applied

During the build process (`build.sh`), patches are:

1. **Copied** to the resources directory
2. **Injected** into `index.html` via script/link tags
3. **Executed** when the wallet loads

**Injection Order**:
```html
<link rel="stylesheet" href="./ios-ui.css">
<script src="./polyfills.js"></script>
<script src="./mobile-ui-panel-button.js"></script>
<script src="./mobile-ui-mcm-import.js"></script>
<script src="./mobile-ui-export.js"></script>
<script src="./mobile-ui-main-screen.js"></script>
<script src="./legal-links.js"></script>
<script type="module" src="./assets/popup-xxx.js"></script>
```

---

## Adding New Patches

To add a new UI patch:

1. **Create the patch file** in `patches/` directory
2. **Add copy logic** to `build.sh` (Step 5)
3. **Add injection logic** to `build.sh` (Step 6)
4. **Document the patch** in this file
5. **Test thoroughly** with a clean build (`./build.sh --clean`)

### JavaScript Patch Template

```javascript
// iOS-only patch: [describe purpose]
(function () {
  var MARK_ATTR = "data-ios-patch-[name]";

  function hide(el, reason) {
    if (!el || el.hasAttribute(MARK_ATTR)) return;
    el.setAttribute(MARK_ATTR, "true");
    el.style.setProperty("display", "none", "important");
    // Remove console.log in production
    // console.log("[iOS Patch] Hidden:", el.tagName, reason);
  }

  function scanAndHide() {
    // Your element detection logic here
  }

  function start() {
    scanAndHide();
    // Re-scan after delays for React/dynamic content
    setTimeout(scanAndHide, 200);
    setTimeout(scanAndHide, 500);
    
    // Observe DOM changes
    var observer = new MutationObserver(scanAndHide);
    if (document.body) {
      observer.observe(document.body, { childList: true, subtree: true });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }
})();
```

### CSS Patch Template

```css
/* iOS-only patch: [describe purpose] */

/* Target specific elements */
.your-selector {
  display: none !important;
}

/* Use attribute selectors for dynamic content */
[data-testid="element-name"] {
  /* styles */
}
```

### build.sh Integration

```bash
# In build.sh Step 5 (copy patches):
NEW_PATCH_SRC="$PATCHES_DIR/new-patch.js"
NEW_PATCH_DST="$RESOURCES_DIR/new-patch.js"
if [ -f "$NEW_PATCH_SRC" ]; then
    cp "$NEW_PATCH_SRC" "$NEW_PATCH_DST"
    echo -e "   ${GREEN}✅ new-patch.js copied${NC}"
fi

# In build.sh Step 6 (script injection):
if [ -f "$NEW_PATCH_DST" ]; then
    SCRIPT_INJECTION="$SCRIPT_INJECTION\n    <script src=\"./new-patch.js\"></script>"
fi
```

### Best Practices

1. **Use marker attributes** to prevent double-processing
2. **Avoid console.log** in production code
3. **Use specific selectors** for performance
4. **Test on multiple iOS versions** and devices
5. **Document why** the patch is needed, not just what it does

---

## Debugging Patches

1. Open Safari on macOS
2. Enable Developer menu (Safari → Preferences → Advanced)
3. Connect iOS device or use Simulator
4. Safari → Develop → [Device] → MochiWallet
5. Use Console to view `[iOS Patch]` log messages
6. Use Elements inspector to verify hidden elements

---

## Patch Compatibility

When updating the upstream extension, verify patches still work:

1. Check if target elements still exist
2. Check if class names have changed
3. Check if component structure has changed
4. Run full test cycle after any extension update
