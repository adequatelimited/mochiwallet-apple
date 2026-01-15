import UIKit
import WebKit
import os.log

// MARK: - Logging

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mochimo.wallet", category: "ViewController")

/// Main view controller that hosts the WKWebView wallet interface
@MainActor
class ViewController: UIViewController {
    
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("ViewController loaded")
        
        setupWebView()
        setupProgressView()
        setupLoadingIndicator()
        loadWallet()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide navigation bar for full-screen experience
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Setup
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        
        // Configure preferences
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        // Enable local storage (equivalent to Android's domStorageEnabled)
        configuration.websiteDataStore = .default()
        
        // Configure user content controller for JavaScript bridge
        let contentController = WKUserContentController()
        
        // Add message handlers for native communication
        contentController.add(self, name: "iOSBridge")
        contentController.add(self, name: "log")
        contentController.add(self, name: "toast")
        
        configuration.userContentController = contentController
        
        // Note: allowFileAccessFromFileURLs is deprecated but needed for local file loading.
        // Using loadFileURL with allowingReadAccessTo handles this properly in modern iOS.
        // The deprecated API is kept as a fallback for older iOS versions.
        if #available(iOS 16.4, *) {
            // Modern iOS handles this through loadFileURL's allowingReadAccessTo parameter
        } else {
            configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        }
        
        // Create WebView
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Configure appearance
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .black
        
        // Disable bounce effect for app-like feel
        webView.scrollView.bounces = false
        webView.scrollView.alwaysBounceVertical = false
        
        // Safe area handling
        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        // Add progress observation
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        view.addSubview(webView)
    }
    
    private func setupProgressView() {
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor(red: 0.4, green: 0.31, blue: 0.64, alpha: 1.0) // Purple theme
        progressView.trackTintColor = .clear
        progressView.isHidden = true
        
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator = UIActivityIndicatorView(style: .large)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadWallet() {
        // Show loading state
        loadingIndicator.startAnimating()
        progressView.isHidden = false
        
        // Load from bundle resources
        guard let resourcePath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "Resources") else {
            logger.error("Wallet resources not found in bundle")
            showError(message: "Wallet resources not found.\nPlease rebuild the app.")
            return
        }
        
        let resourceURL = URL(fileURLWithPath: resourcePath)
        let resourceDirectory = resourceURL.deletingLastPathComponent()
        
        logger.info("Loading wallet from: \(resourceURL.path)")
        
        // Validate the URL before loading
        guard FileManager.default.fileExists(atPath: resourcePath) else {
            logger.error("index.html does not exist at path: \(resourcePath)")
            showError(message: "Wallet files missing.\nPlease reinstall the app.")
            return
        }
        
        // Load with file access enabled
        webView.loadFileURL(resourceURL, allowingReadAccessTo: resourceDirectory)
    }
    
    // MARK: - Progress Observation
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            let progress = Float(webView.estimatedProgress)
            progressView.setProgress(progress, animated: true)
            
            if progress >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.3, options: [], animations: {
                    self.progressView.alpha = 0
                }) { _ in
                    self.progressView.isHidden = true
                    self.progressView.alpha = 1
                    self.progressView.setProgress(0, animated: false)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(message: String) {
        loadingIndicator.stopAnimating()
        progressView.isHidden = true
        
        let errorHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    height: 100vh;
                    margin: 0;
                    background: #1a1a2e;
                    color: white;
                    text-align: center;
                    padding: 20px;
                    box-sizing: border-box;
                }
                h2 { color: #e94560; margin-bottom: 10px; }
                p { color: #a0a0a0; white-space: pre-line; }
            </style>
        </head>
        <body>
            <h2>Failed to Load Wallet</h2>
            <p>\(message)</p>
        </body>
        </html>
        """
        
        webView.loadHTMLString(errorHTML, baseURL: nil)
    }
    
    private func showExitConfirmation() {
        // Note: Apple discourages programmatic app termination (exit(0)).
        // Instead, we inform the user how to properly exit iOS apps.
        let alert = UIAlertController(
            title: "Exit Wallet",
            message: "To exit the app, swipe up from the bottom of the screen (or press the home button) to return to the home screen.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Note: Observer and message handler cleanup handled automatically when view deallocates
        // Accessing webView.configuration in deinit is not safe with strict concurrency
    }
}

// MARK: - WKNavigationDelegate

extension ViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        logger.info("WebView finished loading")
        
        // Inject iOS-specific initialization (equivalent to Android's onPageFinished)
        injectIOSBridge()
    }
    
    /// Injects iOS-specific JavaScript bridge and platform markers
    private func injectIOSBridge() {
        let script = """
        window.IS_IOS = true;
        window.PLATFORM = 'ios';
        console.log('iOS bridge initialized');
        """
        webView.evaluateJavaScript(script) { _, error in
            if let error = error {
                logger.error("Error injecting iOS bridge: \(error.localizedDescription)")
            } else {
                logger.debug("iOS bridge injected successfully")
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        
        // Ignore cancelled requests
        if nsError.code == NSURLErrorCancelled {
            return
        }
        
        logger.error("WebView provisional navigation error: \(error.localizedDescription) (code: \(nsError.code))")
        showError(message: error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        
        if nsError.code == NSURLErrorCancelled {
            return
        }
        
        logger.error("WebView navigation error: \(error.localizedDescription) (code: \(nsError.code))")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        // Security: Only allow file:// and validated https:// URLs
        let scheme = url.scheme?.lowercased() ?? ""
        
        // Handle external links
        if scheme == "https" || scheme == "http" {
            // Validate URL before opening externally
            guard isValidExternalURL(url) else {
                logger.warning("Blocked invalid external URL: \(url.absoluteString)")
                decisionHandler(.cancel)
                return
            }
            
            // Open external links in Safari
            logger.info("Opening external URL in Safari: \(url.host ?? "unknown")")
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }
        
        // Allow file:// URLs (local resources)
        if scheme == "file" {
            decisionHandler(.allow)
            return
        }
        
        // Block other schemes for security
        logger.warning("Blocked URL with scheme: \(scheme)")
        decisionHandler(.cancel)
    }
    
    /// Validates external URLs before opening
    private func isValidExternalURL(_ url: URL) -> Bool {
        // Basic validation - ensure it's a valid HTTP(S) URL
        guard let host = url.host, !host.isEmpty else {
            return false
        }
        // Block javascript: URLs that might slip through
        guard url.scheme == "https" || url.scheme == "http" else {
            return false
        }
        return true
    }
    
    // MARK: - SSL Error Handling (Security)
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Use default system certificate validation for security
        // This properly validates SSL certificates through iOS's trust evaluation
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Perform standard system trust evaluation
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)
        
        if isValid {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            // Log the error for debugging
            if let error = error {
                logger.error("SSL certificate validation failed: \(error.localizedDescription)")
            }
            // Reject invalid certificates
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - WKUIDelegate

extension ViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = defaultText
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(nil)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        present(alert, animated: true)
    }
}

// MARK: - WKScriptMessageHandler

extension ViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        logger.debug("Received message from JS bridge: \(message.name)")
        
        switch message.name {
        case "iOSBridge":
            handleBridgeMessage(message.body)
            
        case "log":
            if let logMessage = message.body as? String {
                logger.info("[WebView] \(logMessage)")
            }
            
        case "toast":
            if let toastMessage = message.body as? String {
                showToast(message: toastMessage)
            }
            
        default:
            logger.warning("Unknown message handler: \(message.name)")
        }
    }
    
    private func handleBridgeMessage(_ body: Any) {
        guard let dict = body as? [String: Any],
              let action = dict["action"] as? String else {
            logger.warning("Invalid bridge message format")
            return
        }
        
        logger.debug("Bridge action: \(action)")
        
        switch action {
        case "getDeviceInfo":
            sendDeviceInfo()
            
        case "vibrate":
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
        case "exit":
            showExitConfirmation()
            
        default:
            logger.warning("Unknown bridge action: \(action)")
        }
    }
    
    /// Sends device information to the web view
    private func sendDeviceInfo() {
        let deviceInfo: [String: Any] = [
            "platform": "ios",
            "version": UIDevice.current.systemVersion,
            "model": UIDevice.current.model,
            "name": UIDevice.current.name
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: deviceInfo),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            logger.error("Failed to serialize device info")
            return
        }
        
        webView.evaluateJavaScript("window.iOSDeviceInfo = \(jsonString);") { _, error in
            if let error = error {
                logger.error("Failed to inject device info: \(error.localizedDescription)")
            }
        }
    }
    
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.numberOfLines = 0
        
        let maxWidth = view.bounds.width - 40
        let size = toastLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        toastLabel.frame = CGRect(
            x: (view.bounds.width - min(size.width + 30, maxWidth)) / 2,
            y: view.bounds.height - 120,
            width: min(size.width + 30, maxWidth),
            height: size.height + 20
        )
        
        view.addSubview(toastLabel)
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.0, options: [], animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}
