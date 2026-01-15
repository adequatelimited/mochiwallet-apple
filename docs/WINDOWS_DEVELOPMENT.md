# Windows Development Guide
## Contributing to Mochimo Wallet iOS from Windows

This guide helps Windows developers contribute to the iOS wallet project despite platform limitations.

---

## The Challenge

iOS app development requires:
- **macOS** operating system
- **Xcode** (Apple's development tool, macOS-only)
- **iOS Simulator** (part of Xcode)

None of these are available on Windows or Linux.

---

## Solution 1: Cloud macOS (Best Option)

Rent a Mac in the cloud and access it remotely.

### Recommended Services

| Service | Price | Best For |
|---------|-------|----------|
| **MacinCloud** | ~$30/month | Individual developers, includes VNC |
| **MacStadium** | ~$99/month | Professional development |
| **AWS EC2 Mac** | ~$1.08/hour | Enterprise/on-demand |

### Setup Steps (Traditional VNC)

1. **Sign up** for a cloud macOS service
2. **Connect** via VNC or remote desktop
3. **Install** Xcode from Mac App Store (on the cloud Mac)
4. **Clone** this repository on the cloud Mac
5. **Develop** using the remote desktop

**Pros**: Full native experience, can test on simulator  
**Cons**: Monthly cost, internet dependency, input lag

### Advanced Setup: VS Code Remote SSH + VNC (Recommended)

This approach combines the best of both worlds:
- **VS Code Remote SSH** for coding with AI assistance (low latency)
- **VNC/Screen Sharing** for viewing Xcode Simulator (when needed)

#### Why This Is Better

✅ **Advantages:**
- GitHub Copilot and AI assistants work normally in VS Code
- Low-latency code editing (text-only SSH)
- Use your local VS Code settings and extensions
- Only use VNC when you need to see the simulator
- Efficient bandwidth usage

❌ **Limitation:**
- Need two connections (SSH + VNC)
- Simulator must be accessed via VNC (graphical)

#### Setup Instructions

1. **Choose a provider with SSH access**
   - MacinCloud: Supports SSH + VNC
   - MacStadium: Full SSH access
   - AWS EC2 Mac: Configure SSH keys

2. **Install VS Code Remote SSH extension**
   ```
   Name: Remote - SSH
   Id: ms-vscode-remote.remote-ssh
   ```

3. **Configure SSH connection**
   
   On Windows, create/edit `C:\Users\YourName\.ssh\config`:
   ```
   Host cloud-mac
       HostName your-mac-ip-or-hostname
       User your-username
       Port 22
       IdentityFile ~/.ssh/your-key
   ```

4. **Connect via VS Code**
   - Press `F1` → "Remote-SSH: Connect to Host"
   - Select `cloud-mac`
   - VS Code reopens connected to remote Mac
   - Open folder: `/path/to/mochiwallet-ios`

5. **Install extensions on remote**
   - Swift extension
   - GitLens
   - Any other tools you need

6. **Install VNC viewer** (for simulator)
   - [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/)
   - [TightVNC](https://www.tightvnc.com/)
   - Windows built-in Remote Desktop (if provider supports)

#### Daily Workflow

**Coding (VS Code Remote SSH):**
```bash
# In VS Code terminal (connected via SSH)
cd mochiwallet-ios
./build.sh

# Edit Swift/JS files with AI assistance
# GitHub Copilot works normally
# Terminal commands work perfectly
```

**Testing (VNC Connection):**
```bash
# In VNC window (viewing Mac desktop)
# Open Simulator.app
# See the app running
# Use Xcode debugger if needed
```

#### What Works Where

| Task | VS Code SSH | VNC Required |
|------|-------------|--------------|
| Edit code | ✅ Perfect | ❌ |
| Run build.sh | ✅ Perfect | ❌ |
| Git operations | ✅ Perfect | ❌ |
| AI assistance | ✅ Perfect | ❌ |
| View simulator | ❌ | ✅ Required |
| Xcode UI | ❌ | ✅ Required |
| Debug breakpoints | ⚠️ Terminal only | ✅ Full |

#### Pro Tips

1. **Build via SSH, view via VNC**
   ```bash
   # SSH terminal in VS Code
   ./build.sh
   # Then switch to VNC to open the app
   ```

2. **Use simulator from command line**
   ```bash
   # Via VS Code SSH terminal
   xcrun simctl list devices
   xcrun simctl boot "iPhone 15"
   xcrun simctl install booted ios/build/Build/Products/Debug-iphonesimulator/MochiWallet.app
   xcrun simctl launch booted com.mochimo.wallet
   # View the running app in VNC window
   ```

3. **Keep VNC minimized** until you need to see something
   - Saves bandwidth
   - Better performance
   - VNC stays connected in background

4. **Use tmux/screen** for persistent sessions
   ```bash
   # In VS Code terminal
   tmux new -s dev
   # Your session persists even if SSH disconnects
   ```

#### Bandwidth Considerations

- **SSH (text/code)**: ~50 KB/s - very efficient
- **VNC (GUI)**: ~500 KB/s - 2 MB/s depending on activity
- **Recommendation**: Code via SSH, only use VNC when testing UI

---

## AI Assistant Integration

### GitHub Copilot & VS Code AI Features

When using **VS Code Remote SSH**, all AI assistants work perfectly:

✅ **Works Normally:**
- GitHub Copilot (code completions)
- GitHub Copilot Chat
- VS Code AI extensions (Tabnine, CodeGPT, etc.)
- IntelliSense and code navigation
- Refactoring suggestions

#### What AI Can Help With

1. **Swift Development**
   ```swift
   // AI can help you:
   // - Complete WKWebView configurations
   // - Suggest proper error handling
   // - Generate boilerplate delegates
   // - Explain iOS APIs
   ```

2. **JavaScript Patches**
   ```javascript
   // AI assistant can:
   // - Generate DOM manipulation code
   // - Suggest MutationObserver patterns
   // - Help with Chrome API polyfills
   // - Debug async issues
   ```

3. **Build Script Improvements**
   ```bash
   # AI can assist with:
   # - Bash scripting
   # - Error handling
   # - Path manipulations
   # - Automation logic
   ```

4. **Documentation**
   - Generate markdown documentation
   - Explain complex code sections
   - Create inline code comments
   - Write commit messages

#### Example AI-Assisted Workflow

```bash
# 1. Connect via VS Code Remote SSH
# 2. Open a Swift file
# 3. Ask Copilot Chat:

"Explain this WKWebView configuration"
"Add error handling to this function"
"Generate a unit test for this method"
"Refactor this to use async/await"

# 4. AI provides instant suggestions
# 5. Accept and test via terminal
# 6. View results in VNC when ready
```

#### Debugging with AI

```
AI can help you:
✅ Analyze build errors
✅ Suggest fixes for compiler warnings
✅ Explain Xcode error messages
✅ Debug JavaScript runtime issues
✅ Identify memory leaks
✅ Optimize performance

Cannot directly:
❌ Click Xcode UI buttons
❌ Set breakpoints in Xcode GUI
❌ Inspect simulator visually
```

#### Best Practices

1. **Use AI for code generation in VS Code**
   - Write comments describing what you need
   - Let Copilot generate the code
   - Test in terminal immediately

2. **Ask AI to explain existing code**
   - Select a code block
   - Right-click → "Copilot: Explain This"
   - Understand before modifying

3. **Use AI for documentation**
   - Generate comprehensive comments
   - Create README sections
   - Write commit messages

4. **Leverage AI for problem-solving**
   ```
   Prompt: "The build.sh script fails at Step 3. Here's the error: [paste error]. How do I fix it?"
   
   AI analyzes and suggests solutions specific to your context.
   ```

---

## Solution 2: Test the Web Extension Locally

The wallet is primarily a web extension. You can develop most features on Windows!

### What You Can Do on Windows

1. **Develop the upstream extension**
   ```bash
   cd mochiwallet
   pnpm install
   pnpm run dev
   ```

2. **Test in Chrome**
   - Open Chrome
   - Go to `chrome://extensions`
   - Enable "Developer mode"
   - Click "Load unpacked"
   - Select the `mochiwallet/dist` folder

3. **Modify patches**
   - Edit JavaScript patches in `patches/` directory
   - Test patches by manually injecting them in Chrome DevTools
   - Example: Copy contents of `patches/polyfills.js` and paste in Console

4. **Update documentation**
   - All documentation is Markdown
   - Edit freely in VS Code or any text editor

### What Requires macOS

- Building the iOS app (`.app` file)
- Testing on iOS Simulator
- Testing native Swift code
- Xcode project configuration changes

---

## Solution 3: Use CI/CD for Verification

Let GitHub Actions build for you!

### Workflow

1. **Make changes** on Windows (patches, docs)
2. **Commit and push** to your fork
3. **Open a PR** to the main repository
4. **GitHub Actions** automatically builds on macOS
5. **Download artifacts** from Actions tab to verify build succeeds

### Example: Testing a JavaScript Patch

```bash
# On Windows
git checkout -b feature/new-patch
notepad patches/my-new-patch.js
# Write your patch code
git add patches/my-new-patch.js
git commit -m "Add new UI patch"
git push origin feature/new-patch
# Open PR on GitHub - CI will build and test
```

---

## Solution 4: Dual Boot / Virtual Machine (Not Recommended)

### Hackintosh (Legal Gray Area)
- Install macOS on PC hardware
- Violates Apple's EULA
- Unstable and time-consuming
- Not recommended for production work

### macOS VM (Very Limited)
- Requires specific AMD CPUs
- Extremely slow performance
- Xcode barely usable
- Not practical for development

---

## Contribution Workflow for Windows Users

### 1. Local Development

Work on what you can locally:

```powershell
# Clone the repo
git clone https://github.com/adequatesystems/mochiwallet-apple.git
cd mochiwallet-apple

# Initialize submodule
git submodule update --init --recursive

# Test the web extension (Node.js required)
cd mochiwallet
npm install -g pnpm  # if not installed
pnpm install
pnpm run dev

# Open Chrome and load extension from dist/
```

### 2. Make Your Changes

Focus on:
- **JavaScript patches** (`patches/*.js`)
- **CSS patches** (`patches/*.css`)
- **Build script improvements** (`build.sh` - use WSL or Git Bash)
- **Documentation** (`*.md`, `docs/*.md`)

### 3. Test Locally

For web extension changes:
1. Build the extension: `cd mochiwallet && pnpm run build`
2. Load in Chrome: `chrome://extensions` → Load unpacked
3. Test wallet functionality

For patches:
1. Manually inject them in Chrome DevTools Console
2. Verify they work as expected
3. Test on different pages/states

### 4. Submit PR

1. Push to your fork on GitHub
2. Open Pull Request
3. CI will build on macOS automatically
4. Maintainers will test on iOS devices

---

## Testing Without iOS Device

Even on macOS, you can test most functionality without a physical device:

### Browser Testing (Any Platform)
```bash
# Test in Chrome DevTools device emulation
1. Open Chrome DevTools (F12)
2. Click device toolbar icon (Ctrl+Shift+M)
3. Select iPhone/iPad
4. Test responsiveness and mobile UI
```

### Remote Testing Services
- [BrowserStack](https://www.browserstack.com/) - Real device testing
- [Sauce Labs](https://saucelabs.com/) - Automated device testing
- [TestFlight](https://testflight.apple.com/) - Beta testing (requires Mac to build)

---

## Quick Reference: What Works Where

| Task | Windows | macOS | Cloud Mac |
|------|---------|-------|-----------|
| Clone repository | ✅ | ✅ | ✅ |
| Edit code/docs | ✅ | ✅ | ✅ |
| Test web extension | ✅ | ✅ | ✅ |
| Run build.sh | ⚠️ WSL | ✅ | ✅ |
| Build iOS app | ❌ | ✅ | ✅ |
| Run iOS Simulator | ❌ | ✅ | ✅ |
| Test on device | ❌ | ✅ | ⚠️ Limited |
| Submit to App Store | ❌ | ✅ | ✅ |

**Legend**: ✅ Fully supported, ⚠️ Partial/workaround, ❌ Not possible

---

## Common Questions

**Q: Can I use WSL (Windows Subsystem for Linux)?**  
A: You can run bash scripts and test the extension build, but you still can't run Xcode or build the iOS app.

**Q: Can I use a remote Mac at work/school?**  
A: Yes! If you have access to a Mac via remote desktop, you can develop normally.

**Q: What about React Native or Flutter?**  
A: This project wraps an existing web extension, not a from-scratch mobile app. Those frameworks don't apply here.

**Q: Can I test on Android instead?**  
A: There's a separate [mochiwallet-android](https://github.com/adequatesystems/mochiwallet-android) repository you can build on Windows.

**Q: Is this worth it?**  
A: If you're making small changes to patches/docs, yes! For major iOS development, consider cloud macOS or partnering with a Mac user.

---

## Recommended Setup for Windows Contributors

### Essential Tools
1. **Git** - [Download](https://git-scm.com/download/win)
2. **Node.js** - [Download](https://nodejs.org/)
3. **VS Code** - [Download](https://code.visualstudio.com/)
4. **Chrome** - For testing extension

### Optional But Helpful
1. **WSL2** - Run Linux on Windows for bash scripts
2. **Docker Desktop** - Container development
3. **Git Bash** - Unix-like terminal on Windows

### VS Code Extensions
- Swift (syntax highlighting only)
- Markdown All in One
- GitLens
- ESLint

---

## Getting Help

- **GitHub Issues**: Ask questions about Windows development
- **Discussions**: Share your Windows workflow tips
- **Discord/Slack**: Connect with other contributors

---

## Summary

As a Windows developer, you can:
- ✅ Contribute to patches and documentation
- ✅ Test the web extension locally
- ✅ Use CI/CD for iOS build verification
- ✅ Use cloud macOS for full development
- ✅ **Use VS Code Remote SSH with AI assistance**
- ❌ Cannot build iOS app natively on Windows

The project welcomes contributions from all platforms! Focus on what you can do, and let CI/CD and Mac users handle the iOS-specific testing.

---

## Quick Start: Cloud Mac + VS Code Remote SSH

### Checklist for Setup

- [ ] **Day 1: Get Cloud Mac Access**
  - [ ] Sign up for MacinCloud or MacStadium
  - [ ] Receive SSH credentials and VNC details
  - [ ] Test VNC connection
  - [ ] Test SSH connection

- [ ] **Day 1: Configure VS Code**
  - [ ] Install "Remote - SSH" extension
  - [ ] Add cloud Mac to SSH config
  - [ ] Test connection via VS Code
  - [ ] Install Swift extension on remote

- [ ] **Day 1: Setup Development Environment**
  ```bash
  # Via VS Code Remote SSH terminal
  xcode-select --install
  git clone https://github.com/adequatesystems/mochiwallet-apple.git
  cd mochiwallet-apple
  git submodule update --init --recursive
  ```

- [ ] **Day 2: Install Dependencies**
  ```bash
  # Install Node.js via Homebrew (if not installed)
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew install node
  corepack enable
  pnpm --version
  ```

- [ ] **Day 2: First Build**
  ```bash
  ./build.sh
  # Watch for any errors
  ```

- [ ] **Day 2: Test with Simulator**
  - [ ] Switch to VNC window
  - [ ] Open Simulator.app
  - [ ] Build and run from Xcode OR
  - [ ] Use command line to launch app

- [ ] **Day 3+: Start Developing**
  - [ ] AI assistant helps with coding
  - [ ] Build via terminal
  - [ ] View in simulator via VNC
  - [ ] Commit and push changes

### Expected Timeline

| Phase | Time | What You'll Do |
|-------|------|----------------|
| **Setup** | 1-2 hours | Sign up, configure VS Code SSH |
| **Environment** | 1 hour | Install Xcode, dependencies |
| **First Build** | 30 mins | Run `./build.sh`, troubleshoot |
| **Learning** | 2-4 hours | Explore codebase with AI help |
| **Development** | Ongoing | Make changes, test, contribute |

### Costs

**Monthly (recommended for regular contribution):**
- MacinCloud: ~$30/month
- MacStadium: ~$99/month

**Hourly (occasional testing):**
- AWS EC2 Mac: ~$1.08/hour (~$24 for 24-hour period)

**One-time:**
- GitHub Codespaces: Free tier available, then pay per hour
