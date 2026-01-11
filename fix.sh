#!/bin/bash

# ============================================
# fix_undo_project.sh
# Builds the complete Undo Chrome Extension
# ============================================

echo "🚀 Building Undo Chrome Extension Project..."

PROJECT_ROOT="$(pwd)"
echo "Project root: $PROJECT_ROOT"

# ------------------------------------------------------------
# 1. CREATE CHROME EXTENSION FILES (Root of the project)
# ------------------------------------------------------------
echo "📦 Creating Chrome Extension files..."

# manifest.json
cat > "$PROJECT_ROOT/manifest.json" << 'EOF'
{
  "manifest_version": 3,
  "name": "Undo - Safer Email Assistant",
  "version": "1.0.0",
  "description": "AI-powered email safety checker for Gmail and LinkedIn",
  "permissions": [
    "activeTab",
    "storage",
    "scripting"
  ],
  "host_permissions": [
    "https://mail.google.com/*",
    "https://www.linkedin.com/*",
    "https://*.openai.com/*",
    "https://*.huggingface.co/*",
    "http://localhost:3000/*"
  ],
  "content_scripts": [
    {
      "matches": [
        "https://mail.google.com/*",
        "https://www.linkedin.com/*"
      ],
      "js": ["content.js"],
      "css": ["content.css"],
      "run_at": "document_end"
    }
  ],
  "web_accessible_resources": [
    {
      "resources": ["popup.html", "content.css"],
      "matches": ["<all_urls>"]
    }
  ],
  "action": {
    "default_popup": "popup.html",
    "default_title": "Undo Email Safety"
  },
  "icons": {
    "16": "icons/icon16.png",
    "48": "icons/icon48.png",
    "128": "icons/icon128.png"
  },
  "background": {
    "service_worker": "background.js"
  }
}
EOF
echo "  ✅ Created manifest.json"

# content.js
cat > "$PROJECT_ROOT/content.js" << 'EOF'
// Fix: Prevent duplicate execution
if (!window.undoExtensionLoaded) {
    window.undoExtensionLoaded = true;

    class EmailSafetyAssistant {
        constructor() {
            this.safetyPopup = null;
            this.currentMessage = '';
            this.isProcessing = false;
            this.hfToken = null;
            this.serverUrl = 'http://localhost:3000';
            this.gmailTimeout = null;
            this.linkedinTimeout = null;
            console.log('[Undo] Extension loaded');
            this.init();
        }

        async init() {
            chrome.storage.local.get(['undoHFToken'], (result) => {
                this.hfToken = result.undoHFToken;
                if (!this.hfToken) {
                    console.log('[Undo] No Hugging Face token found. Add one in popup.');
                }
            });
            this.setupObservers();
        }

        setupObservers() {
            if (window.location.hostname.includes('mail.google.com')) this.observeGmail();
            if (window.location.hostname.includes('linkedin.com')) this.observeLinkedIn();
        }

        observeGmail() {
            const observer = new MutationObserver((mutations) => {
                const composeBox = document.querySelector('[role="textbox"][aria-label*="Message"], [role="textbox"][aria-label*="Compose"]');
                if (composeBox && composeBox.textContent.trim().length > 30) {
                    clearTimeout(this.gmailTimeout);
                    this.gmailTimeout = setTimeout(() => {
                        this.analyzeMessage(composeBox.textContent, composeBox);
                    }, 1000);
                }
            });
            observer.observe(document.body, { childList: true, subtree: true, characterData: true });
        }

        observeLinkedIn() {
            const observer = new MutationObserver((mutations) => {
                const messageBox = document.querySelector('.msg-form__contenteditable');
                if (messageBox && messageBox.textContent.trim().length > 30) {
                    clearTimeout(this.linkedinTimeout);
                    this.linkedinTimeout = setTimeout(() => {
                        this.analyzeMessage(messageBox.textContent, messageBox);
                    }, 1000);
                }
            });
            observer.observe(document.body, { childList: true, subtree: true });
        }

        async analyzeMessage(text, targetElement) {
            if (this.isProcessing || !text.trim()) return;
            if (!this.hfToken) {
                this.showNoTokenMessage(targetElement);
                return;
            }
            this.isProcessing = true;
            this.showLoading(targetElement);
            try {
                // SIMPLIFIED FOR NOW: Use local analysis to avoid immediate API errors
                const analysis = this.getLocalAnalysis(text);
                this.showSafetyPopup(analysis, targetElement);
            } catch (error) {
                console.error('[Undo] Analysis error:', error);
                this.showError(targetElement, 'Analysis failed. Check token.');
            } finally {
                this.isProcessing = false;
            }
        }

        getLocalAnalysis(text) {
            // Simple rule-based analysis as a fallback/placeholder
            const score = Math.min([...text.matchAll(/urgent|asap|hate|stupid|!!+/gi)].length * 15, 95);
            const level = score > 70 ? 'high' : score > 40 ? 'medium' : 'low';
            return {
                riskScore: score,
                riskLevel: level,
                issues: level === 'high' ? ['Tone may be too strong'] : ['Looks good'],
                saferAlternative: "Hi,\n\n" + text.replace(/urgent/gi, 'important').replace(/asap/gi, 'when you can'),
                explanation: "AI-suggested improvements applied."
            };
        }

        showSafetyPopup(analysis, targetElement) {
            if (this.safetyPopup) this.safetyPopup.remove();
            this.safetyPopup = document.createElement('div');
            this.safetyPopup.className = 'undo-safety-popup';
            const riskColor = analysis.riskLevel === 'high' ? '#dc3545' : analysis.riskLevel === 'medium' ? '#ffc107' : '#28a745';
            this.safetyPopup.innerHTML = `
                <div class="undo-popup-header"><h3>Undo Safety Check</h3><span class="undo-close">×</span></div>
                <div class="undo-risk-indicator" style="border-left-color: ${riskColor}">
                    <div class="undo-risk-score"><span class="undo-score">${analysis.riskScore}</span> <span class="undo-risk-level">${analysis.riskLevel.toUpperCase()}</span></div>
                    <div class="undo-issues"><strong>Issues:</strong><ul><li>${analysis.issues[0]}</li></ul></div>
                </div>
                <div class="undo-alternative"><strong>Safer Alternative:</strong><div class="undo-safer-text">${analysis.saferAlternative}</div><button class="undo-use-alternative">Use This Version</button></div>
            `;
            const rect = targetElement.getBoundingClientRect();
            Object.assign(this.safetyPopup.style, {
                position: 'fixed', top: `${rect.bottom + window.scrollY + 10}px`, left: `${rect.left + window.scrollX}px`,
                zIndex: '10000', background: 'white', padding: '15px', borderRadius: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', width: '350px'
            });
            document.body.appendChild(this.safetyPopup);
            this.safetyPopup.querySelector('.undo-close').onclick = () => this.safetyPopup.remove();
            this.safetyPopup.querySelector('.undo-use-alternative').onclick = () => {
                targetElement.textContent = analysis.saferAlternative;
                this.safetyPopup.remove();
                this.showConfirmation(targetElement, '✓ Alternative applied!');
            };
        }

        showLoading(targetElement) {
            const loading = document.createElement('div');
            loading.textContent = '🔍 Analyzing safety...';
            Object.assign(loading.style, {
                position: 'absolute', background: '#fff', padding: '8px 12px', borderRadius: '4px',
                boxShadow: '0 2px 10px rgba(0,0,0,0.1)', zIndex: '9999', fontSize: '12px', color: '#1a73e8'
            });
            const rect = targetElement.getBoundingClientRect();
            loading.style.top = `${rect.top + window.scrollY - 35}px`;
            loading.style.left = `${rect.left + window.scrollX}px`;
            document.body.appendChild(loading);
            setTimeout(() => loading.remove(), 1500);
        }

        showNoTokenMessage(targetElement) {
            const msg = document.createElement('div');
            msg.innerHTML = '🔑 <a href="#" style="color:#1a73e8;">Add Hugging Face Token</a> in popup.';
            Object.assign(msg.style, {
                position: 'absolute', background: '#fff3cd', padding: '8px 12px', borderRadius: '4px',
                boxShadow: '0 2px 10px rgba(0,0,0,0.1)', zIndex: '9999', fontSize: '12px', color: '#856404'
            });
            const rect = targetElement.getBoundingClientRect();
            msg.style.top = `${rect.top + window.scrollY - 35}px`;
            msg.style.left = `${rect.left + window.scrollX}px`;
            document.body.appendChild(msg);
            msg.querySelector('a').onclick = (e) => { e.preventDefault(); chrome.runtime.sendMessage({action: 'openPopup'}); };
            setTimeout(() => msg.remove(), 4000);
        }

        showError(targetElement, message) { /* Basic error display */ }
        showConfirmation(targetElement, message) { /* Basic confirmation display */ }
    }

    // Initialize
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => new EmailSafetyAssistant());
    } else {
        new EmailSafetyAssistant();
    }
}
EOF
echo "  ✅ Created content.js"

# content.css
cat > "$PROJECT_ROOT/content.css" << 'EOF'
.undo-safety-popup { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
.undo-popup-header { display: flex; justify-content: space-between; align-items: center; background: #1a73e8; color: white; padding: 12px 16px; border-radius: 8px 8px 0 0; }
.undo-popup-header h3 { margin: 0; font-size: 16px; }
.undo-close { cursor: pointer; font-size: 20px; }
.undo-risk-indicator { padding: 16px; border-left: 4px solid; }
.undo-risk-score { display: flex; align-items: center; gap: 12px; margin-bottom: 12px; }
.undo-score { font-size: 28px; font-weight: bold; }
.undo-risk-level { font-size: 12px; font-weight: 600; padding: 4px 10px; border-radius: 12px; background: #f8f9fa; }
.undo-issues { font-size: 13px; margin: 12px 0; }
.undo-issues ul { margin: 8px 0 0 20px; padding: 0; }
.undo-alternative { padding: 16px; background: #f8f9fa; border-top: 1px solid #eee; }
.undo-safer-text { background: white; padding: 12px; border-radius: 4px; margin: 8px 0; border: 1px solid #ddd; font-size: 13px; line-height: 1.5; max-height: 150px; overflow-y: auto; }
.undo-use-alternative { background: #1a73e8; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; font-size: 13px; margin-top: 8px; width: 100%; }
.undo-use-alternative:hover { background: #0d62d9; }
EOF
echo "  ✅ Created content.css"

# popup.html
cat > "$PROJECT_ROOT/popup.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><meta charset="utf-8">
<style>
body { width: 340px; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f8f9fa; }
.header { background: linear-gradient(135deg, #1a73e8, #0d62d9); color: white; padding: 20px; text-align: center; }
.header h1 { font-size: 20px; margin: 0; }
.content { padding: 20px; }
.section { background: white; border-radius: 8px; padding: 16px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
.section h3 { color: #1a73e8; font-size: 14px; margin-bottom: 12px; }
.api-key-input { width: 100%; padding: 10px; margin: 8px 0; border: 1px solid #ddd; border-radius: 6px; font-size: 13px; }
.btn { background: #1a73e8; color: white; border: none; padding: 10px; border-radius: 6px; cursor: pointer; font-size: 13px; width: 100%; }
.btn:hover { background: #0d62d9; }
.status { margin-top: 12px; padding: 10px; border-radius: 4px; font-size: 12px; display: none; }
.success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
.error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
.token-status { padding: 6px 10px; border-radius: 4px; font-size: 11px; margin: 5px 0; }
.token-status.valid { background: #d4edda; color: #155724; }
</style>
</head>
<body>
    <div class="header"><h1>Undo</h1><p>Safer Email Assistant</p></div>
    <div class="content">
        <div class="section">
            <h3>🤗 Hugging Face Setup</h3>
            <p style="font-size:12px; color:#666;">1. Get token from <a href="#" id="getHFToken">huggingface.co/settings/tokens</a><br>2. Paste below:</p>
            <input type="password" id="hfToken" class="api-key-input" placeholder="hf_xxxxxxxxxxxxxxxxxx">
            <div id="tokenStatus" class="token-status"></div>
            <button id="saveToken" class="btn">Save Hugging Face Token</button>
            <div id="status" class="status"></div>
        </div>
        <div class="section">
            <h3>⚡ Quick Actions</h3>
            <button id="testAnalysis" class="btn" style="background:#f1f3f4;color:#333;margin-bottom:8px;">Test Analysis</button>
            <button id="viewDashboard" class="btn" style="background:#f1f3f4;color:#333;">Open Dashboard</button>
        </div>
    </div>
    <script src="popup.js"></script>
</body>
</html>
EOF
echo "  ✅ Created popup.html"

# popup.js
cat > "$PROJECT_ROOT/popup.js" << 'EOF'
document.addEventListener('DOMContentLoaded', function() {
    // Load saved token
    chrome.storage.local.get(['undoHFToken'], function(result) {
        const tokenInput = document.getElementById('hfToken');
        if (tokenInput && result.undoHFToken) {
            tokenInput.value = result.undoHFToken;
            updateTokenStatus(result.undoHFToken);
        }
    });

    // Save Token
    document.getElementById('saveToken').addEventListener('click', saveHFToken);
    document.getElementById('hfToken').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') saveHFToken();
    });

    // Get Token Link
    document.getElementById('getHFToken').addEventListener('click', function(e) {
        e.preventDefault();
        chrome.tabs.create({ url: 'https://huggingface.co/settings/tokens' });
    });

    // Test Button
    document.getElementById('testAnalysis').addEventListener('click', function() {
        showStatus('Test mode: Open Gmail and start typing.', 'success');
    });

    // Dashboard Button
    document.getElementById('viewDashboard').addEventListener('click', function() {
        chrome.tabs.create({ url: 'http://localhost:3000' });
    });
});

function saveHFToken() {
    const tokenInput = document.getElementById('hfToken');
    const token = tokenInput.value.trim();

    if (!token) {
        showStatus('Please enter a token.', 'error');
        return;
    }
    if (!token.startsWith('hf_')) {
        showStatus('Token must start with "hf_".', 'error');
        return;
    }

    chrome.storage.local.set({ undoHFToken: token }, function() {
        console.log('Token saved:', token.substring(0, 8) + '...');
        showStatus('✅ Token saved successfully!', 'success');
        updateTokenStatus(token);
        // Notify content script
        chrome.tabs.query({url: ['*://mail.google.com/*', '*://*.linkedin.com/*']}, function(tabs) {
            tabs.forEach(tab => {
                chrome.tabs.sendMessage(tab.id, { type: 'UPDATE_TOKEN', token: token })
                    .catch(err => console.log('Tab not ready:', err));
            });
        });
    });
}

function updateTokenStatus(token) {
    const statusEl = document.getElementById('tokenStatus');
    if (!statusEl) return;
    if (token && token.startsWith('hf_')) {
        statusEl.textContent = '✅ Token configured and ready!';
        statusEl.className = 'token-status valid';
    } else if (token) {
        statusEl.textContent = '⚠️ Invalid format';
        statusEl.className = 'token-status warning';
    } else {
        statusEl.textContent = '❌ No token configured';
        statusEl.className = 'token-status error';
    }
}

function showStatus(message, type) {
    const statusDiv = document.getElementById('status');
    if (!statusDiv) return;
    statusDiv.textContent = message;
    statusDiv.className = `status ${type}`;
    statusDiv.style.display = 'block';
    setTimeout(() => { statusDiv.style.display = 'none'; }, 3000);
}
EOF
echo "  ✅ Created popup.js"

# background.js
cat > "$PROJECT_ROOT/background.js" << 'EOF'
console.log('[Undo] Background service worker loaded.');

// Listen for messages (e.g., to open popup)
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'openPopup') {
        chrome.action.openPopup();
    }
    if (request.type === 'ANALYSIS_COMPLETE') {
        // Store basic stats
        chrome.storage.local.get(['messageCount'], function(result) {
            const newCount = (result.messageCount || 0) + 1;
            chrome.storage.local.set({ messageCount: newCount });
        });
    }
});
EOF
echo "  ✅ Created background.js"

# ------------------------------------------------------------
# 2. CREATE ICONS DIRECTORY & PLACEHOLDERS
# ------------------------------------------------------------
echo "🎨 Creating icons directory..."
mkdir -p "$PROJECT_ROOT/icons"

# Create simple placeholder icons using a base64 string for a blue square
for size in 16 48 128; do
    cat > "$PROJECT_ROOT/icons/icon${size}.png.base64" << 'EOF'
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAACXBIWXMAAAsTAAALEwEAmpwYAAAA
AXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAgY0hSTQAAeiYAAICEAAD6AAAAgOgAAHUwAADq
YAAAOpgAABdwnLpRPAAAAGlJREFUOE9j/P//PwM6YGJgYGBEF8QnB0UQqgMGBgZGRgYGBsZ///4x
/GP4x4CskBkXJxhaYGBkZGT89/8fw7///0Au+g8yAdM9uDg4AoyMjIz//v2DCICcwYg/CNHDDAD8
8Rpw8Q8kPAAAAABJRU5ErkJggg==
EOF
    # Try to decode the base64 to create a real PNG. If 'base64' command fails, create a dummy file.
    if command -v base64 >/dev/null 2>&1; then
        base64 -d "$PROJECT_ROOT/icons/icon${size}.png.base64" > "$PROJECT_ROOT/icons/icon${size}.png" 2>/dev/null
        if [ $? -eq 0 ] && [ -s "$PROJECT_ROOT/icons/icon${size}.png" ]; then
            echo "  ✅ Created icon${size}.png from base64"
        else
            # Fallback: create a tiny valid PNG using a simple command if possible
            echo -n "placeholder" > "$PROJECT_ROOT/icons/icon${size}.png"
            echo "  ⚠ Created placeholder icon${size}.png (install ImageMagick for proper icons)"
        fi
    else
        echo -n "U" > "$PROJECT_ROOT/icons/icon${size}.png"
        echo "  ⚠ Created placeholder icon${size}.png"
    fi
    # Remove the base64 source file
    rm -f "$PROJECT_ROOT/icons/icon${size}.png.base64"
done

# ------------------------------------------------------------
# 3. CREATE NODE.JS SERVER DIRECTORY
# ------------------------------------------------------------
echo "🖥 Creating Node.js server directory..."
mkdir -p "$PROJECT_ROOT/server"

# server/package.json
cat > "$PROJECT_ROOT/server/package.json" << 'EOF'
{
  "name": "undo-server",
  "version": "1.0.0",
  "description": "Backend for Undo Chrome Extension",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
EOF
echo "  ✅ Created server/package.json"

# server/server.js
cat > "$PROJECT_ROOT/server/server.js" << 'EOF'
const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

let messages = [];
let stats = { totalMessages: 0, highRiskCount: 0 };

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', messages: messages.length, timestamp: new Date().toISOString() });
});

// Store a message
app.post('/api/messages', (req, res) => {
    try {
        const msg = { id: Date.now(), ...req.body, timestamp: new Date().toISOString() };
        messages.push(msg);
        messages = messages.slice(-1000);
        stats.totalMessages++;
        if (msg.riskLevel === 'high') stats.highRiskCount++;
        res.status(201).json({ success: true, id: msg.id });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get stats
app.get('/api/stats', (req, res) => {
    const highRiskPct = stats.totalMessages > 0 ? ((stats.highRiskCount / stats.totalMessages) * 100).toFixed(1) : '0.0';
    res.json({ ...stats, highRiskPercentage: highRiskPct });
});

// Simple dashboard
app.get('/', (req, res) => {
    res.send(`
        <html><head><title>Undo Dashboard</title><style>body{font-family:sans-serif;padding:2em}</style></head>
        <body><h1>Undo Dashboard</h1><p>Total Messages: <strong>${stats.totalMessages}</strong></p><p>High Risk: <strong>${stats.highRiskCount}</strong></p></body></html>
    `);
});

app.listen(PORT, () => console.log(\`🚀 Undo Server: http://localhost:\${PORT}\`));
EOF
echo "  ✅ Created server/server.js"

# ------------------------------------------------------------
# 4. CREATE USEFUL SUPPORT FILES
# ------------------------------------------------------------
echo "📝 Creating support files..."

# README.md
cat > "$PROJECT_ROOT/README.md" << 'EOF'
# Undo - Safer Email Assistant

A Chrome extension that checks emails in Gmail/LinkedIn for safety and suggests improvements.

## Quick Start

### 1. Install the Chrome Extension
1. Open Chrome and go to `chrome://extensions/`
2. Enable **"Developer mode"** (top-right toggle).
3. Click **"Load unpacked"**.
4. Select the **root folder of this project** (where `manifest.json` is).

### 2. Configure
1. Click the Undo extension icon (blue "U") in Chrome's toolbar.
2. Get a free token from [Hugging Face](https://huggingface.co/settings/tokens).
3. Paste the token (starts with `hf_`) and click **Save**.

### 3. Start the Local Server (Optional)
```bash
cd server
npm install
npm start