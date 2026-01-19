#!/usr/bin/env bash
# Mochimo Wallet iOS/macOS Build Script
# Builds iOS app from upstream extension submodule
# Version: 0.0.18

set -e  # Exit on error

# Script version
SCRIPT_VERSION="0.0.18"

# Parse arguments
SKIP_EXTENSION_BUILD=false
BUILD_FOR_DEVICE=false
CONFIGURATION="Debug"
VERBOSE=false
CLEAN_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--skip-extension-build)
            SKIP_EXTENSION_BUILD=true
            shift
            ;;
        -d|--device)
            BUILD_FOR_DEVICE=true
            shift
            ;;
        -r|--release)
            CONFIGURATION="Release"
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -h|--help)
            echo "Mochimo Wallet iOS Build Script v$SCRIPT_VERSION"
            echo ""
            echo "Usage: ./build.sh [options]"
            echo ""
            echo "Options:"
            echo "  -s, --skip-extension-build  Skip building the web extension"
            echo "  -d, --device                Build for physical device (requires signing)"
            echo "  -r, --release               Build Release configuration"
            echo "  -v, --verbose               Enable verbose logging for debugging"
            echo "  -c, --clean                 Clean build artifacts before building"
            echo "  -h, --help                  Show this help message"
            echo ""
            echo "Environment Variables:"
            echo "  APPETIZE_API_TOKEN          API token for Appetize.io upload"
            echo "  APPETIZE_PUBLIC_KEY         Public key of existing Appetize app (for updates)"
            echo ""
            echo "Examples:"
            echo "  ./build.sh                  # Full build for simulator"
            echo "  ./build.sh -s               # Skip extension build, use existing dist/"
            echo "  ./build.sh -d -r            # Release build for device"
            echo "  ./build.sh --clean          # Clean build from scratch"
            echo ""
            echo "  # Build and upload to Appetize.io:"
            echo "  APPETIZE_API_TOKEN=your_token ./build.sh"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Verbose logging helper
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${CYAN}[VERBOSE]${NC} $1"
    fi
}

# Error helper with suggestions
error_exit() {
    echo -e "${RED}ERROR: $1${NC}"
    if [ -n "$2" ]; then
        echo -e "${YELLOW}Suggestion: $2${NC}"
    fi
    exit 1
}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}🍎 Mochimo Wallet iOS - Build Script${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Get script directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSION_DIR="$REPO_ROOT/mochiwallet"
IOS_DIR="$REPO_ROOT/ios"
PATCHES_DIR="$REPO_ROOT/patches"
RESOURCES_DIR="$IOS_DIR/MochiWallet/Resources"

log_verbose "REPO_ROOT: $REPO_ROOT"
log_verbose "EXTENSION_DIR: $EXTENSION_DIR"
log_verbose "IOS_DIR: $IOS_DIR"
log_verbose "PATCHES_DIR: $PATCHES_DIR"
log_verbose "RESOURCES_DIR: $RESOURCES_DIR"

# Validate critical directories exist
if [ ! -d "$IOS_DIR" ]; then
    error_exit "iOS directory not found at $IOS_DIR" "Ensure you're running from the repository root."
fi

if [ ! -d "$PATCHES_DIR" ]; then
    error_exit "Patches directory not found at $PATCHES_DIR" "The patches/ directory is required for iOS compatibility."
fi

# Clean build artifacts if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}Cleaning build artifacts...${NC}"
    rm -rf "$IOS_DIR/build"
    rm -rf "$IOS_DIR/DerivedData"
    rm -rf "$RESOURCES_DIR"
    rm -rf "$EXTENSION_DIR/dist"
    rm -rf "$EXTENSION_DIR/node_modules"
    echo -e "${GREEN}✅ Clean complete${NC}"
fi

# Step 1: Check submodule exists (auto-init if missing)
echo -e "${YELLOW}[1/7] Checking submodule...${NC}"
log_verbose "Checking for submodule at $EXTENSION_DIR"
if [ ! -d "$EXTENSION_DIR" ] || [ ! -f "$EXTENSION_DIR/package.json" ]; then
    echo -e "   ${YELLOW}Submodule missing; initializing...${NC}"
    submodule_ready=false

    # Prefer git submodule if this is a git repo
    if [ -d "$REPO_ROOT/.git" ]; then
        log_verbose "Attempting git submodule init..."
        if (cd "$REPO_ROOT" && git submodule update --init --recursive "mochiwallet" >/dev/null 2>&1); then
            if [ -d "$EXTENSION_DIR" ] && [ -f "$EXTENSION_DIR/package.json" ]; then
                submodule_ready=true
            fi
        fi
    fi

    # Fallback: plain git clone if submodule init failed or not a git repo
    if [ "$submodule_ready" = false ]; then
        log_verbose "Submodule init failed, attempting direct clone..."
        rm -rf "$EXTENSION_DIR"
        if git clone https://github.com/adequatesystems/mochiwallet.git "$EXTENSION_DIR" >/dev/null 2>&1; then
            if [ -d "$EXTENSION_DIR" ] && [ -f "$EXTENSION_DIR/package.json" ]; then
                submodule_ready=true
            fi
        fi
    fi

    if [ "$submodule_ready" = false ]; then
        error_exit "mochiwallet submodule not found and auto-init failed!" "Ensure git is installed and run: git submodule update --init --recursive"
    fi

    echo -e "   ${GREEN}✅ Submodule initialized${NC}"
else
    echo -e "   ${GREEN}✅ Submodule present${NC}"
    log_verbose "Submodule found at $EXTENSION_DIR"
fi

# Step 2: Build extension (unless skipped)
if [ "$SKIP_EXTENSION_BUILD" = false ]; then
    echo -e "\n${YELLOW}[2/7] Building web extension...${NC}"
    pushd "$EXTENSION_DIR" > /dev/null
    
    # Check if we need to install/build dependencies
    NEEDS_BUILD=false
    if [ ! -d "node_modules" ] || [ ! -d "node_modules/mochimo-wallet/dist" ] || [ ! -d "node_modules/mochimo-mesh-api-client/dist" ]; then
        NEEDS_BUILD=true
    fi
    
    if [ "$NEEDS_BUILD" = true ]; then
        echo -e "   Installing dependencies..."
        
        # Create pnpm-workspace.yaml with onlyBuiltDependencies if it doesn't exist or is incomplete
        cat > pnpm-workspace.yaml << 'EOF'
packages: []

onlyBuiltDependencies:
  - mochimo-wallet
  - mochimo-wots
  - mochimo-mesh-api-client
EOF
        echo -e "   Created pnpm-workspace.yaml with onlyBuiltDependencies"
        
        # Try normal pnpm install first
        set +e  # Temporarily disable exit on error
        npx pnpm@8 install > /dev/null 2>&1
        INSTALL_RESULT=$?
        set -e
        
        # Check if git dependencies were built successfully
        MOCHI_WALLET_DIST="$EXTENSION_DIR/node_modules/mochimo-wallet/dist"
        MESH_API_DIST="$EXTENSION_DIR/node_modules/mochimo-mesh-api-client/dist"
        
        if [ $INSTALL_RESULT -ne 0 ] || [ ! -d "$MOCHI_WALLET_DIST" ] || [ ! -d "$MESH_API_DIST" ]; then
            echo -e "   ${YELLOW}Git dependencies need manual build (upstream missing onlyBuiltDependencies)...${NC}"
            
            # Install with --ignore-scripts to skip failed builds
            echo -e "   Re-installing with --ignore-scripts..."
            rm -rf node_modules
            npx pnpm@8 install --ignore-scripts
            
            # Build mochimo-wallet manually
            echo -e "   Building mochimo-wallet dependency..."
            TEMP_BUILD_DIR=$(mktemp -d)
            
            # Clone mochimo-wallet
            git clone --depth 1 --branch v1.1.54 https://github.com/adequatesystems/mochimo-wallet.git "$TEMP_BUILD_DIR" > /dev/null 2>&1
            
            pushd "$TEMP_BUILD_DIR" > /dev/null
            
            # Add missing onlyBuiltDependencies to its pnpm-workspace.yaml
            cat > pnpm-workspace.yaml << 'EOF'
packages:
  - 'examples/*'

onlyBuiltDependencies:
  - mochimo-mesh-api-client
  - mochimo-wots
EOF
            
            # Install and build
            set +e
            npx pnpm@8 install > /dev/null 2>&1
            npx vite build > /dev/null 2>&1
            set -e
            
            if [ ! -f "dist/index.js" ]; then
                popd > /dev/null
                rm -rf "$TEMP_BUILD_DIR"
                popd > /dev/null
                error_exit "Failed to build mochimo-wallet" "Check network connectivity and try again. You may need to install dependencies manually."
            fi
            
            # Copy dist to node_modules
            DEST_DIR="$EXTENSION_DIR/node_modules/mochimo-wallet"
            cp -r dist "$DEST_DIR/"
            
            popd > /dev/null
            rm -rf "$TEMP_BUILD_DIR"
            echo -e "   ${GREEN}✅ mochimo-wallet built${NC}"
            
            # Build mochimo-mesh-api-client manually
            echo -e "   Building mochimo-mesh-api-client dependency..."
            TEMP_BUILD_DIR2=$(mktemp -d)
            
            git clone --depth 1 https://github.com/adequatesystems/mochimo-mesh-api-client.git "$TEMP_BUILD_DIR2" > /dev/null 2>&1
            
            pushd "$TEMP_BUILD_DIR2" > /dev/null
            
            set +e
            npm install --ignore-scripts > /dev/null 2>&1
            npx tsup src/index.ts --format cjs,esm --dts > /dev/null 2>&1
            set -e
            
            if [ ! -f "dist/index.js" ]; then
                popd > /dev/null
                rm -rf "$TEMP_BUILD_DIR2"
                popd > /dev/null
                error_exit "Failed to build mochimo-mesh-api-client" "Check network connectivity and try again."
            fi
            
            DEST_DIR2="$EXTENSION_DIR/node_modules/mochimo-mesh-api-client"
            cp -r dist "$DEST_DIR2/"
            
            popd > /dev/null
            rm -rf "$TEMP_BUILD_DIR2"
            echo -e "   ${GREEN}✅ mochimo-mesh-api-client built${NC}"
        else
            echo -e "   ${GREEN}✅ Dependencies installed${NC}"
        fi
    fi
    
    # Build extension
    echo -e "   Building extension..."
    npx pnpm@8 run build
    
    popd > /dev/null
    echo -e "   ${GREEN}✅ Extension built${NC}"
else
    echo -e "\n${YELLOW}[2/7] Skipping extension build (using existing dist/)${NC}"
fi

# Step 3: Apply iOS patches
echo -e "\n${YELLOW}[3/7] Applying iOS patches...${NC}"

# Patch vite.config if not already patched
VITE_CONFIG_PATH="$EXTENSION_DIR/vite.config.ts"
if [ -f "$VITE_CONFIG_PATH" ]; then
    if ! grep -q "base: '\.\/'" "$VITE_CONFIG_PATH"; then
        echo -e "   Patching vite.config.ts..."
        sed -i.bak "s|base: '/'|base: './'|g" "$VITE_CONFIG_PATH"
        rm -f "$VITE_CONFIG_PATH.bak"
        echo -e "   ${GREEN}✅ Patched vite.config.ts${NC}"
    else
        echo -e "   vite.config.ts already patched"
    fi
else
    echo -e "   ${YELLOW}WARNING: vite.config.ts not found${NC}"
fi

# Step 4: Copy assets to iOS
echo -e "\n${YELLOW}[4/7] Copying assets to iOS...${NC}"

DIST_PATH="$EXTENSION_DIR/dist"
log_verbose "Looking for dist at $DIST_PATH"
if [ ! -d "$DIST_PATH" ]; then
    error_exit "Extension dist/ directory not found." "Build the extension first with: ./build.sh (without -s flag)"
fi

# Clear existing resources and recreate
rm -rf "$RESOURCES_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy dist to resources
cp -r "$DIST_PATH"/* "$RESOURCES_DIR/"
FILE_COUNT=$(find "$RESOURCES_DIR" -type f | wc -l | tr -d ' ')
echo -e "   ${GREEN}✅ Copied $FILE_COUNT files${NC}"

# Step 5: Add polyfills.js and optional UI overrides
echo -e "\n${YELLOW}[5/7] Adding iOS polyfills and UI overrides...${NC}"

POLYFILLS_SRC="$PATCHES_DIR/polyfills.js"
POLYFILLS_DST="$RESOURCES_DIR/polyfills.js"
IOS_UI_CSS_SRC="$PATCHES_DIR/ios-ui.css"
IOS_UI_CSS_DST="$RESOURCES_DIR/ios-ui.css"
HIDE_SIDEBAR_SRC="$PATCHES_DIR/mobile-ui-panel-button.js"
HIDE_SIDEBAR_DST="$RESOURCES_DIR/mobile-ui-panel-button.js"
HIDE_MCM_SRC="$PATCHES_DIR/mobile-ui-mcm-import.js"
HIDE_MCM_DST="$RESOURCES_DIR/mobile-ui-mcm-import.js"
HIDE_EXPORT_SRC="$PATCHES_DIR/mobile-ui-export.js"
HIDE_EXPORT_DST="$RESOURCES_DIR/mobile-ui-export.js"
MOBILE_UI_MAIN_SRC="$PATCHES_DIR/mobile-ui-main-screen.js"
MOBILE_UI_MAIN_DST="$RESOURCES_DIR/mobile-ui-main-screen.js"
LEGAL_LINKS_SRC="$PATCHES_DIR/legal-links.js"
LEGAL_LINKS_DST="$RESOURCES_DIR/legal-links.js"

if [ -f "$POLYFILLS_SRC" ]; then
    cp "$POLYFILLS_SRC" "$POLYFILLS_DST"
    echo -e "   ${GREEN}✅ polyfills.js copied${NC}"
    log_verbose "Copied polyfills.js from $POLYFILLS_SRC"
else
    error_exit "polyfills.js not found in patches/" "This file is critical for iOS compatibility. Restore it from the repository."
fi

if [ -f "$IOS_UI_CSS_SRC" ]; then
    cp "$IOS_UI_CSS_SRC" "$IOS_UI_CSS_DST"
    echo -e "   ${GREEN}✅ ios-ui.css copied${NC}"
else
    echo -e "   ${YELLOW}(optional) ios-ui.css not found in patches/${NC}"
fi

if [ -f "$HIDE_SIDEBAR_SRC" ]; then
    cp "$HIDE_SIDEBAR_SRC" "$HIDE_SIDEBAR_DST"
    echo -e "   ${GREEN}✅ mobile-ui-panel-button.js copied${NC}"
else
    echo -e "   ${YELLOW}(optional) mobile-ui-panel-button.js not found in patches/${NC}"
fi

if [ -f "$HIDE_MCM_SRC" ]; then
    cp "$HIDE_MCM_SRC" "$HIDE_MCM_DST"
    echo -e "   ${GREEN}✅ mobile-ui-mcm-import.js copied${NC}"
else
    echo -e "   ${YELLOW}(optional) mobile-ui-mcm-import.js not found in patches/${NC}"
fi

if [ -f "$HIDE_EXPORT_SRC" ]; then
    cp "$HIDE_EXPORT_SRC" "$HIDE_EXPORT_DST"
    echo -e "   ${GREEN}✅ mobile-ui-export.js copied${NC}"
else
    echo -e "   ${YELLOW}(optional) mobile-ui-export.js not found in patches/${NC}"
fi

if [ -f "$MOBILE_UI_MAIN_SRC" ]; then
    cp "$MOBILE_UI_MAIN_SRC" "$MOBILE_UI_MAIN_DST"
    echo -e "   ${GREEN}✅ mobile-ui-main-screen.js copied (main screen customizations)${NC}"
else
    echo -e "   ${YELLOW}(optional) mobile-ui-main-screen.js not found in patches/${NC}"
fi

if [ -f "$LEGAL_LINKS_SRC" ]; then
    cp "$LEGAL_LINKS_SRC" "$LEGAL_LINKS_DST"
    echo -e "   ${GREEN}✅ legal-links.js copied (Terms of Service and Privacy Policy links)${NC}"
else
    echo -e "   ${YELLOW}(optional) legal-links.js not found in patches/${NC}"
fi

# Step 6: Fix index.html
echo -e "\n${YELLOW}[6/7] Fixing index.html...${NC}"

INDEX_PATH="$RESOURCES_DIR/index.html"
log_verbose "Fixing index.html at $INDEX_PATH"
if [ ! -f "$INDEX_PATH" ]; then
    error_exit "index.html not found in resources!" "The extension may not have built correctly. Try running without -s flag."
fi

# Create temporary file for modifications
TEMP_INDEX=$(mktemp)
cp "$INDEX_PATH" "$TEMP_INDEX"

# Remove require('buffer') line
grep -v "window.Buffer.*require.*buffer" "$TEMP_INDEX" > "$TEMP_INDEX.new" && mv "$TEMP_INDEX.new" "$TEMP_INDEX"
# OLD: sed -i.bak "s|window\.Buffer = window\.Buffer || require(['\"]buffer['\"]).Buffer;||g" "$TEMP_INDEX"

# Fix absolute asset paths to relative paths for WKWebView
sed -i.bak 's|src="/assets/|src="./assets/|g' "$TEMP_INDEX"
sed -i.bak 's|href="/assets/|href="./assets/|g' "$TEMP_INDEX"

# Add iOS UI stylesheet if not present
if ! grep -q "ios-ui.css" "$TEMP_INDEX"; then
    if [ -f "$IOS_UI_CSS_DST" ]; then
        echo -e "   Adding ios-ui.css link..."
        sed -i.bak 's|</head>|    <link rel="stylesheet" href="./ios-ui.css">\n</head>|g' "$TEMP_INDEX"
    fi
fi

# Remove any existing polyfill/hide script tags (to avoid duplicates)
sed -i.bak '/<script src="\.\/polyfills\.js"><\/script>/d' "$TEMP_INDEX"
sed -i.bak '/<script src="\.\/mobile-ui-panel-button\.js"><\/script>/d' "$TEMP_INDEX"
sed -i.bak '/<script src="\.\/mobile-ui-mcm-import\.js"><\/script>/d' "$TEMP_INDEX"
sed -i.bak '/<script src="\.\/mobile-ui-export\.js"><\/script>/d' "$TEMP_INDEX"
sed -i.bak '/<script src="\.\/mobile-ui-main-screen\.js"><\/script>/d' "$TEMP_INDEX"
sed -i.bak '/<script src="\.\/legal-links\.js"><\/script>/d' "$TEMP_INDEX"

# Build script injection string
SCRIPT_INJECTION='    <script src="./polyfills.js"></script>'
if [ -f "$HIDE_SIDEBAR_DST" ]; then
    SCRIPT_INJECTION="$SCRIPT_INJECTION\n    <script src=\"./mobile-ui-panel-button.js\"></script>"
fi
if [ -f "$HIDE_MCM_DST" ]; then
    SCRIPT_INJECTION="$SCRIPT_INJECTION\n    <script src=\"./mobile-ui-mcm-import.js\"></script>"
fi
if [ -f "$HIDE_EXPORT_DST" ]; then
    SCRIPT_INJECTION="$SCRIPT_INJECTION\n    <script src=\"./mobile-ui-export.js\"></script>"
fi
if [ -f "$MOBILE_UI_MAIN_DST" ]; then
    SCRIPT_INJECTION="$SCRIPT_INJECTION\n    <script src=\"./mobile-ui-main-screen.js\"></script>"
fi
if [ -f "$LEGAL_LINKS_DST" ]; then
    SCRIPT_INJECTION="$SCRIPT_INJECTION\n    <script src=\"./legal-links.js\"></script>"
fi

# Inject scripts before the module popup script
if grep -q 'type="module".*popup-' "$TEMP_INDEX"; then
    echo -e "   Injecting polyfills and optional hide scripts before popup bundle..."
    # Use perl for more reliable multiline substitution
    perl -i -pe "s|(<script type=\"module\"[^>]*popup-)|$SCRIPT_INJECTION\n\$1|" "$TEMP_INDEX"
else
    echo -e "   ${YELLOW}WARNING: module popup script not found; appending scripts at end of <head>${NC}"
    sed -i.bak "s|</head>|$SCRIPT_INJECTION\n</head>|g" "$TEMP_INDEX"
fi

# Clean up backup files and move result
rm -f "$TEMP_INDEX.bak"
mv "$TEMP_INDEX" "$INDEX_PATH"
echo -e "   ${GREEN}✅ index.html fixed${NC}"

# Step 7: Build iOS App
echo -e "\n${YELLOW}[7/7] Building iOS App...${NC}"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    error_exit "xcodebuild not found. Please install Xcode and command line tools." "Run: xcode-select --install"
fi

log_verbose "xcodebuild found at $(which xcodebuild)"

# Determine destination
if [ "$BUILD_FOR_DEVICE" = true ]; then
    DESTINATION="generic/platform=iOS"
    echo -e "   Building for physical device..."
else
    # Get default simulator
    SIMULATOR_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -oE '[0-9A-F-]{36}')
    if [ -z "$SIMULATOR_ID" ]; then
        DESTINATION="platform=iOS Simulator,name=iPhone 15"
    else
        DESTINATION="platform=iOS Simulator,id=$SIMULATOR_ID"
    fi
    echo -e "   Building for simulator..."
fi

pushd "$IOS_DIR" > /dev/null

# Build the app
echo -e "   Running xcodebuild..."
xcodebuild \
    -project MochiWallet.xcodeproj \
    -scheme MochiWallet \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    -derivedDataPath build \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    ONLY_ACTIVE_ARCH=NO \
    build 2>&1 | tee /tmp/xcodebuild.log

BUILD_RESULT=${PIPESTATUS[0]}

popd > /dev/null

if [ $BUILD_RESULT -ne 0 ]; then
    error_exit "iOS build failed!" "Check the Xcode output above for details. Common issues:\n  - Missing code signing: Use -d flag only for device builds\n  - Xcode not configured: Run 'sudo xcode-select -s /Applications/Xcode.app'\n  - License not accepted: Run 'sudo xcodebuild -license accept'"
fi

echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Show app info
if [ "$BUILD_FOR_DEVICE" = true ]; then
    APP_PATH="$IOS_DIR/build/Build/Products/$CONFIGURATION-iphoneos/MochiWallet.app"
else
    APP_PATH="$IOS_DIR/build/Build/Products/$CONFIGURATION-iphonesimulator/MochiWallet.app"
fi

if [ -d "$APP_PATH" ]; then
    APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
    echo ""
    echo -e "${CYAN}App Location:${NC}"
    echo -e "   $APP_PATH"
    echo -e "   Size: $APP_SIZE"
fi

echo ""
echo -e "${YELLOW}To run on simulator:${NC}"
echo -e "   open ios/MochiWallet.xcodeproj"
echo -e "   Select simulator and press Cmd+R"
echo ""

# Step 8: Upload to Appetize.io (optional)
if [ -n "$APPETIZE_API_TOKEN" ]; then
    echo -e "\n${YELLOW}[8/8] Uploading to Appetize.io...${NC}"
    
    if [ -d "$APP_PATH" ]; then
        # Create a zip of the .app bundle for Appetize using ditto (preserves symlinks)
        ZIP_PATH="$IOS_DIR/build/MochiWallet.zip"
        echo -e "   Creating zip archive with ditto..."
        ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
        
        if [ -f "$ZIP_PATH" ]; then
            ZIP_SIZE=$(du -sh "$ZIP_PATH" | cut -f1)
            echo -e "   Zip size: $ZIP_SIZE"
            
            # Upload to Appetize.io
            echo -e "   Uploading to Appetize.io..."
            
            # Check if we have an existing app to update
            if [ -n "$APPETIZE_PUBLIC_KEY" ]; then
                # Update existing app
                APPETIZE_RESPONSE=$(curl -s -X POST "https://api.appetize.io/v1/apps/$APPETIZE_PUBLIC_KEY" \
                    -H "X-API-KEY: $APPETIZE_API_TOKEN" \
                    -F "file=@$ZIP_PATH" \
                    -F "platform=ios")
            else
                # Create new app
                APPETIZE_RESPONSE=$(curl -s -X POST "https://api.appetize.io/v1/apps" \
                    -H "X-API-KEY: $APPETIZE_API_TOKEN" \
                    -F "file=@$ZIP_PATH" \
                    -F "platform=ios")
            fi
            
            # Parse response
            if echo "$APPETIZE_RESPONSE" | grep -q '"publicKey"'; then
                PUBLIC_KEY=$(echo "$APPETIZE_RESPONSE" | grep -o '"publicKey":"[^"]*"' | cut -d'"' -f4)
                APP_URL="https://appetize.io/app/$PUBLIC_KEY"
                echo -e "   ${GREEN}✅ Upload successful!${NC}"
                echo -e ""
                echo -e "${CYAN}Appetize.io Test URL:${NC}"
                echo -e "   $APP_URL"
                echo -e ""
                echo -e "${YELLOW}Note:${NC} Save the publicKey for future updates: $PUBLIC_KEY"
                
                # Output for CI systems
                if [ -n "$GITHUB_OUTPUT" ]; then
                    echo "appetize_url=$APP_URL" >> "$GITHUB_OUTPUT"
                    echo "appetize_public_key=$PUBLIC_KEY" >> "$GITHUB_OUTPUT"
                fi
            else
                echo -e "   ${RED}❌ Upload failed!${NC}"
                echo -e "   Response: $APPETIZE_RESPONSE"
            fi
            
            # Cleanup zip
            rm -f "$ZIP_PATH"
        else
            echo -e "   ${RED}❌ Failed to create zip archive${NC}"
        fi
    else
        echo -e "   ${RED}❌ App not found at $APP_PATH${NC}"
    fi
else
    echo -e "${CYAN}Tip:${NC} Set APPETIZE_API_TOKEN environment variable to auto-upload to Appetize.io for testing"
fi
