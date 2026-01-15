// iOS-only patch: hide the panel toggle button
(function () {
  var MARK_ATTR = "data-ios-hidden-panel";

  function hide(el) {
    if (!el || el.hasAttribute(MARK_ATTR)) return;
    el.setAttribute(MARK_ATTR, "true");
    el.style.setProperty("display", "none", "important");
  }

  function scanAndHide() {
    // First try: Look for buttons with data attributes or aria labels
    document.querySelectorAll('[data-testid*="panel"], [aria-label*="panel" i], [aria-label*="expand" i]').forEach(function (btn) {
      hide(btn);
    });
    
    // Find all buttons in the header area
    var headerButtons = document.querySelectorAll("[class*='border-b'] button, header button");
    
    headerButtons.forEach(function (btn) {
      if (btn.hasAttribute(MARK_ATTR)) return;
      
      var svg = btn.querySelector("svg");
      if (!svg) return;
      
      var rect = svg.querySelector("rect");
      var lines = svg.querySelectorAll("line");
      
      // Skip if it has 3 lines (menu icon)
      if (lines.length === 3) return;
      
      var parent = btn.parentElement;
      if (!parent) return;
      
      // PanelRight icon detection: has rect and 0-2 lines
      if (rect && lines.length <= 2) {
        hide(btn);
        return;
      }
      
      // Fallback: check for aria-label or title mentioning panel
      var label = (btn.getAttribute("aria-label") || btn.getAttribute("title") || "").toLowerCase();
      if (label.indexOf("panel") !== -1 || label.indexOf("expand") !== -1) {
        hide(btn);
        return;
      }
    });
  }

  function start() {
    scanAndHide();
    // Re-scan after delays in case React renders components later
    setTimeout(scanAndHide, 200);
    setTimeout(scanAndHide, 500);
    setTimeout(scanAndHide, 1000);
    
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
