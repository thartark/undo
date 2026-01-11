#!/bin/bash
# fix_setup.sh - Fixes your current setup and adds missing files
echo "🔧 Fixing your TextCraft Pro setup..."

# Navigate to your project root (where your GitHub repo is)
cd /Users/anthonyhartman/code/undo

# Create the missing server.js
cat > server.js << 'EOF'
// TextCraft Pro Development Server
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml'
};

const server = http.createServer((req, res) => {
  console.log(`${req.method} ${req.url}`);
  
  // Serve extension files
  let filePath = '.' + req.url;
  if (filePath === './') {
    filePath = './test.html';
  }
  
  const extname = path.extname(filePath);
  let contentType = MIME_TYPES[extname] || 'application/octet-stream';
  
  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        // File not found
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end('<h1>404 Not Found</h1><p>TextCraft Pro test server</p>');
      } else {
        // Server error
        res.writeHead(500);
        res.end('Server Error: ' + error.code);
      }
    } else {
      // Success
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(PORT, () => {
  console.log(`🚀 TextCraft Pro development server running at:`);
  console.log(`   http://localhost:${PORT}`);
  console.log(`   http://localhost:${PORT}/test.html`);
  console.log(`\n📦 Extension files are ready to load in Chrome:`);
  console.log(`   1. Open chrome://extensions/`);
  console.log(`   2. Enable "Developer mode"`);
  console.log(`   3. Click "Load unpacked"`);
  console.log(`   4. Select this directory: ${process.cwd()}`);
  console.log(`\n🔄 Server will automatically serve your files`);
});
EOF

# Create a proper test.html file
cat > test.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>TextCraft Pro Test Page</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .test-area { margin: 20px 0; padding: 20px; border: 1px solid #ccc; }
        textarea, input { width: 100%; padding: 10px; margin: 10px 0; }
        button { padding: 10px 20px; margin: 5px; }
    </style>
</head>
<body>
    <h1>✏️ TextCraft Pro Test Page</h1>
    <p>Use this page to test your extension. Focus on any text field below and click the TextCraft Pro extension icon.</p>
    
    <div class="test-area">
        <h2>Text Area Test</h2>
        <textarea id="testTextarea" rows="10" placeholder="Type here to test undo/redo, transformations, and stats..."></textarea>
    </div>
    
    <div class="test-area">
        <h2>Input Field Test</h2>
        <input type="text" id="testInput" placeholder="Type here to test on input fields...">
        <input type="email" id="testEmail" placeholder="email@example.com">
    </div>
    
    <div class="test-area">
        <h2>ContentEditable Test</h2>
        <div id="editableDiv" contenteditable="true" style="border:1px solid #ccc; padding:10px; min-height:100px;">
            Click here and type to test on contenteditable elements...
        </div>
    </div>
    
    <div class="test-area">
        <h2>Manual Testing</h2>
        <button onclick="document.getElementById('testTextarea').value = document.getElementById('testTextarea').value.toUpperCase()">
            UPPERCASE (Manual)
        </button>
        <button onclick="document.getElementById('testTextarea').value = document.getElementById('testTextarea').value.toLowerCase()">
            lowercase (Manual)
        </button>
        <button onclick="alert('Words: ' + document.getElementById('testTextarea').value.trim().split(/\s+/).length)">
            Count Words
        </button>
    </div>
    
    <script>
        // Add some sample text for testing
        document.getElementById('testTextarea').value = `This is sample text for testing TextCraft Pro.

Try these features:
1. Click the extension icon while focused here
2. Use undo/redo (↶ ↷)
3. Transform text to UPPERCASE/lowercase
4. Check word/character counts

The quick brown fox jumps over the lazy dog.`;

        // Auto-save contenteditable changes
        document.getElementById('editableDiv').addEventListener('input', function() {
            console.log('ContentEditable changed:', this.textContent.substring(0, 50));
        });
    </script>
</body>
</html>
EOF

# Check what files you already have
echo ""
echo "📁 Current directory contents:"
ls -la

echo ""
echo "🔍 Checking for existing Chrome extension files..."

# If manifest.json exists, show it
if [ -f "manifest.json" ]; then
    echo "✅ Found manifest.json"
    echo "   Name: $(grep '"name"' manifest.json | head -1)"
    echo "   Version: $(grep '"version"' manifest.json | head -1)"
else
    echo "❌ No manifest.json found. Creating basic one..."
    cat > manifest.json << 'EOF'
{
  "manifest_version": 3,
  "name": "TextCraft Pro",
  "version": "1.0.0",
  "description": "Enhanced text editing with undo/redo and AI tools",
  "permissions": ["activeTab", "storage"],
  "action": {
    "default_popup": "popup.html",
    "default_icon": {
      "16": "icons/icon16.png",
      "48": "icons/icon48.png",
      "128": "icons/icon128.png"
    }
  },
  "content_scripts": [{
    "matches": ["<all_urls>"],
    "js": ["content.js"],
    "run_at": "document_idle"
  }],
  "icons": {
    "16": "icons/icon16.png",
    "48": "icons/icon48.png",
    "128": "icons/icon128.png"
  }
}
EOF
fi

# Create icons directory if needed
mkdir -p icons

# Create simple icons (if they don't exist)
if [ ! -f "icons/icon16.png" ]; then
    echo "Creating placeholder icons..."
    # Create simple SVG icons
    cat > icons/icon16.svg << 'EOF'
<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg">
  <rect width="16" height="16" fill="#667eea"/>
  <text x="8" y="11" text-anchor="middle" fill="white" font-size="10" font-family="Arial">T</text>
</svg>
EOF
    convert icons/icon16.svg icons/icon16.png 2>/dev/null || echo "PNG" > icons/icon16.png
    cp icons/icon16.png icons/icon48.png
    cp icons/icon16.png icons/icon128.png
fi

# Create basic extension files if missing
if [ ! -f "popup.html" ]; then
    echo "Creating popup.html..."
    cat > popup.html << 'EOF'
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
            <p class="subtitle">Smart Text Editor</p>
        </header>
        
        <div class="section">
            <h2>History</h2>
            <div class="button-group">
                <button id="undoBtn" class="btn primary">↶ Undo</button>
                <button id="redoBtn" class="btn primary">↷ Redo</button>
            </div>
        </div>
        
        <div class="section">
            <h2>Transform</h2>
            <div class="button-group">
                <button id="upperBtn" class="btn">UPPER</button>
                <button id="lowerBtn" class="btn">lower</button>
                <button id="titleBtn" class="btn">Title</button>
            </div>
        </div>
        
        <div class="section">
            <h2>Stats</h2>
            <div class="stats">
                <div class="stat">
                    <span class="label">Words:</span>
                    <span id="wordCount" class="value">0</span>
                </div>
                <div class="stat">
                    <span class="label">Chars:</span>
                    <span id="charCount" class="value">0</span>
                </div>
            </div>
        </div>
        
        <div class="section">
            <button id="settingsBtn" class="btn secondary">⚙️ Settings</button>
        </div>
    </div>
    <script src="popup.js"></script>
</body>
</html>
EOF
fi

if [ ! -f "popup.css" ]; then
    echo "Creating popup.css..."
    cat > popup.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    width: 320px;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
    background: #f5f5f5;
    color: #333;
}

.container {
    padding: 16px;
}

header {
    text-align: center;
    margin-bottom: 20px;
    padding-bottom: 15px;
    border-bottom: 2px solid #e0e0e0;
}

h1 {
    font-size: 20px;
    color: #667eea;
    margin-bottom: 4px;
}

.subtitle {
    font-size: 12px;
    color: #666;
}

.section {
    background: white;
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 12px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

h2 {
    font-size: 14px;
    margin-bottom: 12px;
    color: #444;
}

.button-group {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
}

.btn {
    padding: 10px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-weight: 600;
    transition: all 0.2s;
    font-size: 12px;
}

.btn.primary {
    background: #667eea;
    color: white;
}

.btn.secondary {
    background: #e0e0e0;
    color: #333;
}

.btn:hover {
    opacity: 0.9;
    transform: translateY(-1px);
}

.stats {
    display: flex;
    justify-content: space-around;
}

.stat {
    text-align: center;
}

.stat .label {
    display: block;
    font-size: 12px;
    color: #666;
    margin-bottom: 4px;
}

.stat .value {
    display: block;
    font-size: 24px;
    font-weight: bold;
    color: #667eea;
}
EOF
fi

if [ ! -f "popup.js" ]; then
    echo "Creating popup.js..."
    cat > popup.js << 'EOF'
document.addEventListener('DOMContentLoaded', function() {
    // Get elements
    const undoBtn = document.getElementById('undoBtn');
    const redoBtn = document.getElementById('redoBtn');
    const upperBtn = document.getElementById('upperBtn');
    const lowerBtn = document.getElementById('lowerBtn');
    const titleBtn = document.getElementById('titleBtn');
    const settingsBtn = document.getElementById('settingsBtn');
    const wordCountEl = document.getElementById('wordCount');
    const charCountEl = document.getElementById('charCount');
    
    // Update stats
    function updateStats() {
        chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
            chrome.tabs.sendMessage(tabs[0].id, {action: "getStats"}, function(response) {
                if (response && !chrome.runtime.lastError) {
                    wordCountEl.textContent = response.words || 0;
                    charCountEl.textContent = response.chars || 0;
                }
            });
        });
    }
    
    // Send command to content script
    function sendCommand(action, data = {}) {
        chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
            chrome.tabs.sendMessage(tabs[0].id, {
                action: action,
                data: data
            }, function(response) {
                if (response && response.success) {
                    updateStats();
                }
            });
        });
    }
    
    // Button event listeners
    undoBtn.addEventListener('click', () => sendCommand('undo'));
    redoBtn.addEventListener('click', () => sendCommand('redo'));
    upperBtn.addEventListener('click', () => sendCommand('transform', {type: 'uppercase'}));
    lowerBtn.addEventListener('click', () => sendCommand('transform', {type: 'lowercase'}));
    titleBtn.addEventListener('click', () => sendCommand('transform', {type: 'titlecase'}));
    settingsBtn.addEventListener('click', () => {
        chrome.runtime.openOptionsPage();
    });
    
    // Initial load
    updateStats();
    
    // Update stats every second
    setInterval(updateStats, 1000);
});
EOF
fi

if [ ! -f "content.js" ]; then
    echo "Creating content.js..."
    cat > content.js << 'EOF'
// TextCraft Pro - Content Script
console.log('TextCraft Pro loaded');

class TextCraft {
    constructor() {
        this.history = [];
        this.position = -1;
        this.maxHistory = 100;
        this.autoSave = true;
        
        this.init();
    }
    
    init() {
        // Load history from storage
        chrome.storage.local.get(['textcraft_history'], (result) => {
            if (result.textcraft_history) {
                this.history = result.textcraft_history;
                this.position = this.history.length - 1;
            }
        });
        
        // Listen for text changes
        document.addEventListener('input', this.handleInput.bind(this), true);
        
        // Listen for messages from popup
        chrome.runtime.onMessage.addListener(this.handleMessage.bind(this));
        
        console.log('TextCraft Pro initialized');
    }
    
    handleInput(event) {
        const element = event.target;
        if (this.isTextElement(element) && this.autoSave) {
            this.saveState(element.value, element);
        }
    }
    
    handleMessage(request, sender, sendResponse) {
        const element = this.getActiveTextElement();
        
        switch(request.action) {
            case 'undo':
                this.undo(element);
                sendResponse({success: true});
                break;
                
            case 'redo':
                this.redo(element);
                sendResponse({success: true});
                break;
                
            case 'transform':
                this.transformText(element, request.data.type);
                sendResponse({success: true});
                break;
                
            case 'getStats':
                const stats = this.getTextStats(element);
                sendResponse(stats);
                break;
                
            default:
                sendResponse({success: false, error: 'Unknown action'});
        }
        
        return true; // Keep message channel open for async response
    }
    
    isTextElement(element) {
        return (
            element.tagName === 'TEXTAREA' ||
            (element.tagName === 'INPUT' && element.type === 'text') ||
            (element.tagName === 'INPUT' && element.type === 'email') ||
            (element.tagName === 'INPUT' && element.type === 'password') ||
            (element.tagName === 'INPUT' && element.type === 'search') ||
            (element.tagName === 'INPUT' && element.type === 'url') ||
            element.isContentEditable
        );
    }
    
    getActiveTextElement() {
        const active = document.activeElement;
        if (this.isTextElement(active)) {
            return active;
        }
        // Fallback to first textarea
        return document.querySelector('textarea, input[type="text"]');
    }
    
    saveState(text, element) {
        // Don't save if text hasn't changed
        if (this.history.length > 0 && this.history[this.position] === text) {
            return;
        }
        
        // Remove future history if we're not at the end
        this.history = this.history.slice(0, this.position + 1);
        
        // Add new state
        this.history.push(text);
        this.position++;
        
        // Limit history size
        if (this.history.length > this.maxHistory) {
            this.history.shift();
            this.position--;
        }
        
        // Save to storage
        chrome.storage.local.set({textcraft_history: this.history});
    }
    
    undo(element) {
        if (this.position > 0 && element) {
            this.position--;
            const text = this.history[this.position];
            this.setText(element, text);
        }
    }
    
    redo(element) {
        if (this.position < this.history.length - 1 && element) {
            this.position++;
            const text = this.history[this.position];
            this.setText(element, text);
        }
    }
    
    setText(element, text) {
        if (element.tagName === 'TEXTAREA' || element.tagName === 'INPUT') {
            element.value = text;
        } else if (element.isContentEditable) {
            element.textContent = text;
        }
        
        // Trigger input event
        element.dispatchEvent(new Event('input', {bubbles: true}));
        element.dispatchEvent(new Event('change', {bubbles: true}));
    }
    
    transformText(element, type) {
        if (!element) return;
        
        let currentText = element.tagName === 'TEXTAREA' || element.tagName === 'INPUT' 
            ? element.value 
            : element.textContent;
        
        let transformedText = currentText;
        
        switch(type) {
            case 'uppercase':
                transformedText = currentText.toUpperCase();
                break;
            case 'lowercase':
                transformedText = currentText.toLowerCase();
                break;
            case 'titlecase':
                transformedText = currentText.replace(/\b\w/g, char => char.toUpperCase());
                break;
        }
        
        this.setText(element, transformedText);
        this.saveState(transformedText, element);
    }
    
    getTextStats(element) {
        if (!element) {
            return {words: 0, chars: 0, lines: 0};
        }
        
        const text = element.tagName === 'TEXTAREA' || element.tagName === 'INPUT' 
            ? element.value 
            : element.textContent;
        
        const words = text.trim() ? text.trim().split(/\s+/).length : 0;
        const chars = text.length;
        const lines = text.split('\n').length;
        
        return {words, chars, lines};
    }
}

// Initialize TextCraft Pro
const textcraft = new TextCraft();

// Make it globally available for debugging
window.TextCraftPro = textcraft;
EOF
fi

# Create options page if needed
if [ ! -f "options.html" ]; then
    echo "Creating options.html..."
    cat > options.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial; padding: 20px; max-width: 500px; }
        .option { margin: 15px 0; }
        label { display: block; margin: 5px 0; }
        button { padding: 10px 20px; background: #667eea; color: white; border: none; }
    </style>
</head>
<body>
    <h1>TextCraft Pro Settings</h1>
    <div class="option">
        <label>
            <input type="checkbox" id="autoSave"> Auto-save text changes
        </label>
    </div>
    <div class="option">
        <label>Max undo history:
            <input type="number" id="maxHistory" min="10" max="1000" value="100">
        </label>
    </div>
    <button id="save">Save Settings</button>
    <script src="options.js"></script>
</body>
</html>
EOF
fi

if [ ! -f "options.js" ]; then
    cat > options.js << 'EOF'
document.getElementById('save').onclick = function() {
    const settings = {
        autoSave: document.getElementById('autoSave').checked,
        maxHistory: parseInt(document.getElementById('maxHistory').value)
    };
    chrome.storage.local.set({settings: settings}, function() {
        alert('Settings saved!');
    });
};

// Load saved settings
chrome.storage.local.get(['settings'], function(result) {
    if (result.settings) {
        document.getElementById('autoSave').checked = result.settings.autoSave;
        document.getElementById('maxHistory').value = result.settings.maxHistory;
    }
});
EOF
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "📦 YOUR EXTENSION IS READY!"
echo "----------------------------"
echo "1. Start the development server:"
echo "   node server.js"
echo ""
echo "2. Load the extension in Chrome:"
echo "   - Open chrome://extensions/"
echo "   - Enable 'Developer mode'"
echo "   - Click 'Load unpacked'"
echo "   - Select: $(pwd)"
echo ""
echo "3. Test it:"
echo "   - Open http://localhost:3000"
echo "   - Click the TextCraft Pro icon"
echo "   - Try undo/redo and transformations"
echo ""
echo "📁 Files created/modified:"
ls -la *.js *.html *.css *.json 2>/dev/null || true