# Contributing to Mochimo Wallet iOS

Thank you for your interest in contributing to the Mochimo Wallet iOS app!

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/adequatesystems/mochiwallet-apple.git
   cd mochiwallet-apple
   git submodule update --init --recursive
   ```

2. **Install prerequisites**
   - Xcode 15.2+
   - Node.js 18+
   - pnpm 8+

3. **Build and run**
   ```bash
   ./build.sh
   open ios/MochiWallet.xcodeproj
   ```

## Project Structure

- `ios/` - Native iOS/Swift code
- `patches/` - JavaScript and CSS patches for WKWebView compatibility
- `mochiwallet/` - Git submodule pointing to upstream extension
- `docs/` - Technical documentation

## Making Changes

### iOS-Specific Changes

For changes to the iOS wrapper (Swift code, Xcode project):
1. Make changes in the `ios/` directory
2. Test on simulator and physical device
3. Ensure no Xcode warnings or errors

### Patch Changes

For changes to how the extension runs in WKWebView:
1. Edit files in `patches/` directory
2. Update `build.sh` if adding new patches
3. Document changes in `docs/UI_PATCHES.md`
4. Test thoroughly with a clean build

### Documentation

- Update `docs/TECHNICAL_DOCUMENTATION.md` for technical changes
- Update `README.md` for user-facing changes
- Add changelog entry in technical docs

## Code Style

### Swift
- Follow Apple's Swift API Design Guidelines
- Use `@MainActor` for UI-related code
- Add documentation comments for public APIs
- Use structured concurrency where applicable

### JavaScript
- Use IIFE pattern for patches to avoid global scope pollution
- Use marker attributes to prevent double-processing
- Avoid console.log in production code

### CSS
- Use CSS custom properties for theming
- Support safe area insets for all devices
- Include reduced motion and high contrast media queries

## Testing

Before submitting a PR:

1. **Clean build**: `./build.sh --clean`
2. **Simulator test**: Test on multiple iOS versions (15.0, 17.0+)
3. **Device test**: Test on physical device if possible
4. **Edge cases**:
   - New wallet creation
   - Wallet import
   - Transaction flow
   - App background/foreground
   - Different device sizes

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes with clear commit messages
3. Update documentation as needed
4. Test thoroughly
5. Submit PR with description of changes

## License

By contributing, you agree that your contributions will be licensed under the Mochimo Cryptocurrency Engine License Agreement.

## Questions?

Open an issue for questions or discussion about potential changes.
