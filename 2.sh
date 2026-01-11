#!/bin/bash
# 01_install_basic.sh
echo "Installing basic TextCraft Pro extension with undo/redo..."

# Create basic manifest
cat > TextCraftPro/core/manifest.json << 'EOF'
{
  "manifest_version": 3,
  "name": "TextCraft Pro - Basic",
  "version": "1.0.0",
  "description": "Enhanced text editing for Chrome",
  "permissions": ["activeTab", "storage", "scripting"],
  "action": {
    "default_popup": "popup.html",
    "default_icon": "icon.png"
  },
  "icons": {
    "16": "icon16.png",
    "48": "icon48.png",
    "128": "icon128.png"
  },
  "content_scripts": [{
    "matches": ["<all_urls>"],
    "js": ["content.js"],
    "css": ["content.css"]
  }],
  "background": {
    "service_worker": "background.js"
  },
  "web_accessible_resources": [{
    "resources": ["*.html", "*.css", "*.js", "*.png"],
    "matches": ["<all_urls>"]
  }]
}
EOF

# Create basic assets
cat > TextCraftPro/core/popup.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>TextCraft Pro</title>
  <link rel="stylesheet" href="popup.css">
</head>
<body>
  <div class="container">
    <header>
      <h1>✏️ TextCraft Pro</h1>
      <p class="subtitle">Enhanced Text Editor</p>
    </header>
    
    <div class="feature-section">
      <h2>Quick Actions</h2>
      <div class="button-grid">
        <button id="undoBtn" class="btn btn-primary">↶ Undo</button>
        <button id="redoBtn" class="btn btn-primary">↷ Redo</button>
        <button id="uppercaseBtn" class="btn">UPPERCASE</button>
        <button id="lowercaseBtn" class="btn">lowercase</button>
      </div>
    </div>
    
    <div class="stats-section">
      <h2>Text Stats</h2>
      <div class="stats">
        <div class="stat-item">
          <span class="stat-label">Words:</span>
          <span id="wordCount" class="stat-value">0</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">Chars:</span>
          <span id="charCount" class="stat-value">0</span>
        </div>
      </div>
    </div>
    
    <div class="history-section">
      <h2>History</h2>
      <div id="historyList" class="history-list">
        <!-- History items will appear here -->
      </div>
    </div>
  </div>
  <script src="popup.js"></script>
</body>
</html>
EOF

# Create CSS
cat > TextCraftPro/core/popup.css << 'EOF'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  width: 320px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.container {
  padding: 16px;
}

header {
  text-align: center;
  margin-bottom: 20px;
  padding-bottom: 15px;
  border-bottom: 2px solid rgba(255, 255, 255, 0.1);
}

h1 {
  font-size: 22px;
  margin-bottom: 5px;
}

.subtitle {
  opacity: 0.8;
  font-size: 12px;
}

.feature-section, .stats-section, .history-section {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 10px;
  padding: 15px;
  margin-bottom: 15px;
  backdrop-filter: blur(10px);
}

h2 {
  font-size: 16px;
  margin-bottom: 12px;
  color: #fff;
}

.button-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.btn {
  padding: 10px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.btn:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.btn-primary {
  background: #4CAF50;
}

.btn-primary:hover {
  background: #45a049;
}

.stats {
  display: flex;
  justify-content: space-around;
}

.stat-item {
  text-align: center;
}

.stat-label {
  display: block;
  font-size: 12px;
  opacity: 0.8;
}

.stat-value {
  display: block;
  font-size: 24px;
  font-weight: bold;
}

.history-list {
  max-height: 150px;
  overflow-y: auto;
}

.history-item {
  background: rgba(255, 255, 255, 0.1);
  padding: 8px;
  margin-bottom: 5px;
  border-radius: 5px;
  font-size: 12px;
  cursor: pointer;
}

.history-item:hover {
  background: rgba(255, 255, 255, 0.2);
}
EOF

# Create popup.js
cat > TextCraftPro/core/popup.js << 'EOF'
document.addEventListener('DOMContentLoaded', function() {
  // Get elements
  const undoBtn = document.getElementById('undoBtn');
  const redoBtn = document.getElementById('redoBtn');
  const uppercaseBtn = document.getElementById('uppercaseBtn');
  const lowercaseBtn = document.getElementById('lowercaseBtn');
  const wordCountEl = document.getElementById('wordCount');
  const charCountEl = document.getElementById('charCount');
  const historyList = document.getElementById('historyList');
  
  // Update stats
  function updateStats() {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      chrome.tabs.sendMessage(tabs[0].id, {action: "getStats"}, function(response) {
        if (response) {
          wordCountEl.textContent = response.words;
          charCountEl.textContent = response.chars;
        }
      });
    });
  }
  
  // Send command to content script
  function sendCommand(command, data = {}) {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      chrome.tabs.sendMessage(tabs[0].id, {
        action: "command",
        command: command,
        data: data
      }, function(response) {
        if (response && response.success) {
          updateStats();
          loadHistory();
        }
      });
    });
  }
  
  // Load history
  function loadHistory() {
    chrome.storage.local.get(['textHistory'], function(result) {
      const history = result.textHistory || [];
      historyList.innerHTML = '';
      
      history.slice(-10).reverse().forEach((item, index) => {
        const div = document.createElement('div');
        div.className = 'history-item';
        div.textContent = item.text.substring(0, 50) + (item.text.length > 50 ? '...' : '');
        div.title = `Restore: ${item.text}`;
        div.onclick = () => sendCommand('restore', {text: item.text});
        historyList.appendChild(div);
      });
    });
  }
  
  // Button event listeners
  undoBtn.addEventListener('click', () => sendCommand('undo'));
  redoBtn.addEventListener('click', () => sendCommand('redo'));
  uppercaseBtn.addEventListener('click', () => sendCommand('transform', {type: 'uppercase'}));
  lowercaseBtn.addEventListener('click', () => sendCommand('transform', {type: 'lowercase'}));
  
  // Initial load
  updateStats();
  loadHistory();
  
  // Update stats every 2 seconds
  setInterval(updateStats, 2000);
});
EOF

# Create content.js
cat > TextCraftPro/core/content.js << 'EOF'
// History stack for undo/redo
let historyStack = [];
let historyIndex = -1;
let currentText = '';

// Initialize
function init() {
  // Listen for messages from popup
  chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    if (request.action === "command") {
      handleCommand(request.command, request.data, sendResponse);
      return true;
    } else if (request.action === "getStats") {
      sendResponse(getTextStats());
      return true;
    }
  });
  
  // Add textarea/input listeners for auto-save
  document.addEventListener('input', handleTextChange, true);
  document.addEventListener('change', handleTextChange, true);
  
  // Initialize history from storage
  chrome.storage.local.get(['textHistory'], function(result) {
    if (result.textHistory) {
      historyStack = result.textHistory;
      historyIndex = historyStack.length - 1;
    }
  });
}

// Handle text changes
function handleTextChange(e) {
  if (e.target.tagName === 'TEXTAREA' || e.target.tagName === 'INPUT') {
    saveToHistory(e.target.value);
  }
}

// Save text to history
function saveToHistory(text) {
  if (text === currentText) return;
  
  currentText = text;
  historyStack.push({
    text: text,
    timestamp: new Date().toISOString()
  });
  
  // Limit history size
  if (historyStack.length > 100) {
    historyStack = historyStack.slice(-100);
  }
  
  historyIndex = historyStack.length - 1;
  
  // Save to storage
  chrome.storage.local.set({textHistory: historyStack});
}

// Get active text element
function getActiveElement() {
  const active = document.activeElement;
  if (active.tagName === 'TEXTAREA' || active.tagName === 'INPUT') {
    return active;
  }
  // Try to find any textarea or contenteditable
  const textarea = document.querySelector('textarea, [contenteditable="true"]');
  return textarea || null;
}

// Handle commands from popup
function handleCommand(command, data, callback) {
  const element = getActiveElement();
  if (!element) {
    callback({success: false, error: 'No text element found'});
    return;
  }
  
  switch(command) {
    case 'undo':
      if (historyIndex > 0) {
        historyIndex--;
        const prevText = historyStack[historyIndex].text;
        element.value = prevText;
        element.dispatchEvent(new Event('input', {bubbles: true}));
        callback({success: true});
      }
      break;
      
    case 'redo':
      if (historyIndex < historyStack.length - 1) {
        historyIndex++;
        const nextText = historyStack[historyIndex].text;
        element.value = nextText;
        element.dispatchEvent(new Event('input', {bubbles: true}));
        callback({success: true});
      }
      break;
      
    case 'transform':
      if (data.type === 'uppercase') {
        element.value = element.value.toUpperCase();
      } else if (data.type === 'lowercase') {
        element.value = element.value.toLowerCase();
      }
      element.dispatchEvent(new Event('input', {bubbles: true}));
      callback({success: true});
      break;
      
    case 'restore':
      element.value = data.text;
      element.dispatchEvent(new Event('input', {bubbles: true}));
      callback({success: true});
      break;
      
    default:
      callback({success: false, error: 'Unknown command'});
  }
}

// Get text statistics
function getTextStats() {
  const element = getActiveElement();
  if (!element) return {words: 0, chars: 0};
  
  const text = element.value || '';
  const words = text.trim() ? text.trim().split(/\s+/).length : 0;
  const chars = text.length;
  
  return {words, chars};
}

// Initialize when page loads
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
EOF

# Create background.js
cat > TextCraftPro/core/background.js << 'EOF'
// Background service worker for TextCraft Pro

// Handle extension installation
chrome.runtime.onInstalled.addListener(function(details) {
  if (details.reason === 'install') {
    // Initialize storage
    chrome.storage.local.set({
      textHistory: [],
      settings: {
        autoSave: true,
        maxHistory: 100,
        darkMode: false
      }
    });
    
    // Show welcome page
    chrome.tabs.create({
      url: chrome.runtime.getURL('welcome.html')
    });
  }
});

// Handle messages from content scripts
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  if (request.action === "saveText") {
    chrome.storage.local.get(['textHistory'], function(result) {
      const history = result.textHistory || [];
      history.push({
        text: request.text,
        timestamp: new Date().toISOString(),
        url: sender.tab ? sender.tab.url : 'unknown'
      });
      
      // Limit history size
      if (history.length > 100) {
        history = history.slice(-100);
      }
      
      chrome.storage.local.set({textHistory: history});
    });
  }
  sendResponse({success: true});
});
EOF

# Create welcome page
cat > TextCraftPro/core/welcome.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Welcome to TextCraft Pro</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
      line-height: 1.6;
    }
    h1 {
      color: #667eea;
    }
    .feature {
      background: #f5f5f5;
      padding: 10px;
      margin: 10px 0;
      border-radius: 5px;
    }
  </style>
</head>
<body>
  <h1>🎉 Welcome to TextCraft Pro!</h1>
  <p>Your enhanced text editor is now installed and ready to use.</p>
  
  <h2>✨ Basic Features:</h2>
  <div class="feature">
    <strong>↶ Undo/Redo:</strong> Unlimited history for any text field
  </div>
  <div class="feature">
    <strong>📊 Text Stats:</strong> Real-time word and character counts
  </div>
  <div class="feature">
    <strong>🔄 Text Transformations:</strong> UPPERCASE/lowercase conversions
  </div>
  
  <h2>🚀 How to use:</h2>
  <ol>
    <li>Click the TextCraft Pro icon in your toolbar</li>
    <li>Focus on any text field or textarea</li>
    <li>Use the buttons in the popup to transform text</li>
    <li>Your text history is automatically saved</li>
  </ol>
  
  <button id="closeBtn" style="padding: 10px 20px; background: #667eea; color: white; border: none; border-radius: 5px; cursor: pointer;">
    Get Started!
  </button>
  
  <script>
    document.getElementById('closeBtn').addEventListener('click', function() {
      window.close();
    });
  </script>
</body>
</html>
EOF

# Create simple icons (placeholder)
echo "Creating placeholder icons..."
convert -size 16x16 xc:#667eea TextCraftPro/core/icon16.png 2>/dev/null || echo "Using fallback icon method"
echo "✅ Basic extension files created!"

# Create test HTML file
cat > TextCraftPro/core/test.html << 'EOF'
<!DOCTYPE html>
<html>
<body>
  <h1>TextCraft Pro Test Page</h1>
  <textarea id="testText" rows="10" cols="50" placeholder="Type here to test the extension..."></textarea>
  <br><br>
  <input type="text" placeholder="Test input field..." style="width: 300px; padding: 10px;">
</body>
</html>
EOF

echo "📦 Basic extension created!"
echo ""
echo "To install in Chrome:"
echo "1. Open chrome://extensions/"
echo "2. Enable 'Developer mode'"
echo "3. Click 'Load unpacked'"
echo "4. Select the 'TextCraftPro/core' directory"
echo ""
echo "Test with: open TextCraftPro/core/test.html"