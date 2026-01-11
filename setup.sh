#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    Undo Chrome Extension + Server Setup    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"

# Check if we're in the right directory
if [ -f "manifest.json" ]; then
    echo -e "${YELLOW}⚠  Already in undo directory. Continuing setup...${NC}"
else
    echo -e "${GREEN}✓ Creating undo directory...${NC}"
    mkdir -p undo
    cd undo
fi

# Create directory structure
echo -e "${GREEN}✓ Creating folder structure...${NC}"
mkdir -p icons server

# 1. Create Chrome Extension Files
echo -e "\n${BLUE}[1/4] Creating Chrome Extension Files...${NC}"

# manifest.json
cat > manifest.json << 'EOF'
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
    "http://localhost:3000/*"
  ],
  "content_scripts": [
    {
      "matches": [
        "https://mail.google.com/*",
        "https://www.linkedin.com/*"
      ],
      "js": ["content.js"],
      "css": ["content.css"]
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
echo -e "${GREEN}✓ Created manifest.json${NC}"

# content.js
cat > content.js << 'EOF'
class EmailSafetyAssistant {
    constructor() {
        this.safetyPopup = null;
        this.currentMessage = '';
        this.isProcessing = false;
        this.apiKey = null;
        this.serverUrl = 'http://localhost:3000';
        
        console.log('Undo extension loaded');
        this.init();
    }

    async init() {
        chrome.storage.local.get(['undoApiKey'], (result) => {
            this.apiKey = result.undoApiKey;
        });

        this.setupObservers();
        this.injectStyles();
    }

    setupObservers() {
        if (window.location.hostname === 'mail.google.com') {
            this.observeGmail();
        }
        
        if (window.location.hostname === 'www.linkedin.com') {
            this.observeLinkedIn();
        }
    }

    observeGmail() {
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                const composeBox = document.querySelector('[role="textbox"][aria-label*="Message"], [role="textbox"][aria-label*="Compose"]');
                if (composeBox && composeBox.textContent.trim().length > 50) {
                    this.analyzeMessage(composeBox.textContent, composeBox);
                }
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true,
            attributes: true,
            characterData: true
        });
    }

    observeLinkedIn() {
        const observer = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
                const messageBox = document.querySelector('.msg-form__contenteditable');
                if (messageBox && messageBox.textContent.trim().length > 30) {
                    this.analyzeMessage(messageBox.textContent, messageBox);
                }
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
    }

    async analyzeMessage(text, targetElement) {
        if (this.isProcessing || !text.trim() || !this.apiKey) return;
        
        this.isProcessing = true;
        this.currentMessage = text;
        
        this.showLoading(targetElement);
        
        try {
            const analysis = await this.getSafetyAnalysis(text);
            this.showSafetyPopup(analysis, targetElement);
            await this.storeMessageHistory(text, analysis);
        } catch (error) {
            console.error('Analysis error:', error);
            this.showError(targetElement);
        } finally {
            this.isProcessing = false;
        }
    }

    async getSafetyAnalysis(text) {
        console.log('Analyzing message with AI...');
        
        // For demo purposes - return mock data
        // In production, replace with real OpenAI API call
        return new Promise(resolve => {
            setTimeout(() => {
                resolve({
                    riskScore: Math.floor(Math.random() * 100),
                    riskLevel: ['low', 'medium', 'high'][Math.floor(Math.random() * 3)],
                    issues: [
                        "Potential tone issue detected",
                        "Consider being more specific",
                        "Could be misinterpreted"
                    ],
                    saferAlternative: "Here's a more professional version: " + text.substring(0, 100) + "...",
                    explanation: "This suggestion improves clarity and professionalism."
                });
            }, 1000);
        });
        
        /* REAL OpenAI API code (uncomment when you have API key):
        const response = await fetch('https://api.openai.com/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.apiKey}`
            },
            body: JSON.stringify({
                model: 'gpt-3.5-turbo',
                messages: [{
                    role: 'system',
                    content: 'Analyze email safety and provide safer alternative in JSON format'
                }, {
                    role: 'user',
                    content: text
                }]
            })
        });
        return await response.json();
        */
    }

    showSafetyPopup(analysis, targetElement) {
        if (this.safetyPopup) this.safetyPopup.remove();

        this.safetyPopup = document.createElement('div');
        this.safetyPopup.className = 'undo-safety-popup';
        
        const riskColor = analysis.riskLevel === 'high' ? '#dc3545' : 
                         analysis.riskLevel === 'medium' ? '#ffc107' : '#28a745';
        
        this.safetyPopup.innerHTML = `
            <div class="undo-popup-header">
                <h3>Undo Safety Check</h3>
                <span class="undo-close">&times;</span>
            </div>
            <div class="undo-risk-indicator" style="border-left-color: ${riskColor}">
                <div class="undo-risk-score">
                    <span class="undo-score">${analysis.riskScore}</span>
                    <span class="undo-risk-level">${analysis.riskLevel.toUpperCase()} RISK</span>
                </div>
                <div class="undo-issues">
                    <strong>Potential Issues:</strong>
                    <ul>
                        ${analysis.issues.map(issue => `<li>${issue}</li>`).join('')}
                    </ul>
                </div>
            </div>
            <div class="undo-alternative">
                <strong>Safer Alternative:</strong>
                <div class="undo-safer-text">${analysis.saferAlternative}</div>
                <button class="undo-use-alternative">Use This Version</button>
            </div>
            <div class="undo-explanation">
                ${analysis.explanation}
            </div>
        `;

        const rect = targetElement.getBoundingClientRect();
        this.safetyPopup.style.cssText = `
            position: absolute;
            top: ${rect.bottom + window.scrollY + 10}px;
            left: ${rect.left + window.scrollX}px;
            z-index: 10000;
        `;

        document.body.appendChild(this.safetyPopup);

        this.safetyPopup.querySelector('.undo-close').addEventListener('click', () => {
            this.safetyPopup.remove();
        });

        this.safetyPopup.querySelector('.undo-use-alternative').addEventListener('click', () => {
            this.replaceText(targetElement, analysis.saferAlternative);
            this.safetyPopup.remove();
        });
    }

    replaceText(targetElement, newText) {
        targetElement.textContent = newText;
        targetElement.dispatchEvent(new Event('input', { bubbles: true }));
        targetElement.dispatchEvent(new Event('change', { bubbles: true }));
    }

    async storeMessageHistory(text, analysis) {
        try {
            await fetch(`${this.serverUrl}/api/messages`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    original: text.substring(0, 500),
                    alternative: analysis.saferAlternative,
                    riskScore: analysis.riskScore,
                    riskLevel: analysis.riskLevel,
                    timestamp: new Date().toISOString(),
                    url: window.location.href
                })
            });
        } catch (error) {
            console.log('Note: Server not running, skipping history storage');
        }
    }

    showLoading(targetElement) {
        const loading = document.createElement('div');
        loading.className = 'undo-loading';
        loading.textContent = '🔍 Analyzing safety...';
        loading.style.cssText = `
            position: absolute;
            background: #fff;
            padding: 8px 12px;
            border-radius: 4px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            z-index: 9999;
            font-size: 12px;
        `;
        
        const rect = targetElement.getBoundingClientRect();
        loading.style.top = `${rect.top + window.scrollY - 30}px`;
        loading.style.left = `${rect.left + window.scrollX}px`;
        
        document.body.appendChild(loading);
        setTimeout(() => loading.remove(), 2000);
    }

    showError(targetElement) {
        const error = document.createElement('div');
        error.textContent = '⚠ Analysis failed. Check API key.';
        error.style.cssText = `
            position: absolute;
            background: #fee;
            padding: 8px 12px;
            border-radius: 4px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            z-index: 9999;
            font-size: 12px;
            color: #c33;
        `;
        
        const rect = targetElement.getBoundingClientRect();
        error.style.top = `${rect.top + window.scrollY - 30}px`;
        error.style.left = `${rect.left + window.scrollX}px`;
        
        document.body.appendChild(error);
        setTimeout(() => error.remove(), 3000);
    }

    injectStyles() {
        if (!document.getElementById('undo-styles')) {
            const link = document.createElement('link');
            link.id = 'undo-styles';
            link.rel = 'stylesheet';
            link.href = chrome.runtime.getURL('content.css');
            document.head.appendChild(link);
        }
    }
}

// Initialize when page loads
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => new EmailSafetyAssistant());
} else {
    new EmailSafetyAssistant();
}
EOF
echo -e "${GREEN}✓ Created content.js${NC}"

# content.css
cat > content.css << 'EOF'
.undo-safety-popup {
    width: 380px;
    background: white;
    border-radius: 8px;
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    overflow: hidden;
    animation: undo-slideIn 0.3s ease;
    border: 1px solid #e0e0e0;
}

@keyframes undo-slideIn {
    from {
        opacity: 0;
        transform: translateY(-10px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.undo-popup-header {
    background: #1a73e8;
    color: white;
    padding: 12px 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.undo-popup-header h3 {
    margin: 0;
    font-size: 16px;
    font-weight: 500;
}

.undo-close {
    cursor: pointer;
    font-size: 20px;
    line-height: 1;
    padding: 0 4px;
}

.undo-close:hover {
    opacity: 0.8;
}

.undo-risk-indicator {
    padding: 16px;
    border-left: 4px solid #28a745;
}

.undo-risk-score {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-bottom: 12px;
}

.undo-score {
    font-size: 28px;
    font-weight: bold;
    color: #333;
}

.undo-risk-level {
    font-size: 12px;
    font-weight: 600;
    padding: 4px 10px;
    border-radius: 12px;
    background: #f8f9fa;
    color: #333;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.undo-issues {
    margin: 12px 0;
    font-size: 13px;
}

.undo-issues ul {
    margin: 8px 0 0 0;
    padding-left: 20px;
    color: #666;
}

.undo-issues li {
    margin-bottom: 4px;
    line-height: 1.4;
}

.undo-alternative {
    padding: 16px;
    background: #f8f9fa;
    border-top: 1px solid #eee;
    border-bottom: 1px solid #eee;
}

.undo-safer-text {
    background: white;
    padding: 12px;
    border-radius: 4px;
    margin: 8px 0;
    border: 1px solid #ddd;
    font-size: 13px;
    line-height: 1.5;
    max-height: 150px;
    overflow-y: auto;
    white-space: pre-wrap;
    word-wrap: break-word;
}

.undo-use-alternative {
    background: #1a73e8;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 13px;
    margin-top: 8px;
    width: 100%;
    font-weight: 500;
    transition: background 0.2s;
}

.undo-use-alternative:hover {
    background: #0d62d9;
}

.undo-explanation {
    padding: 12px 16px;
    font-size: 12px;
    color: #666;
    line-height: 1.5;
}

.undo-loading {
    font-size: 12px;
    color: #1a73e8;
}
EOF
echo -e "${GREEN}✓ Created content.css${NC}"

# popup.html
cat > popup.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        
        body {
            width: 340px;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f8f9fa;
        }
        
        .header {
            background: linear-gradient(135deg, #1a73e8, #0d62d9);
            color: white;
            padding: 20px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 4px;
        }
        
        .header p {
            font-size: 12px;
            opacity: 0.9;
        }
        
        .content {
            padding: 20px;
        }
        
        .section {
            background: white;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 16px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        
        .section h3 {
            color: #1a73e8;
            font-size: 14px;
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .section h3 i {
            font-size: 16px;
        }
        
        .api-key-input {
            width: 100%;
            padding: 10px 12px;
            margin: 8px 0;
            border: 1px solid #ddd;
            border-radius: 6px;
            font-size: 13px;
            transition: border 0.2s;
        }
        
        .api-key-input:focus {
            outline: none;
            border-color: #1a73e8;
            box-shadow: 0 0 0 2px rgba(26, 115, 232, 0.1);
        }
        
        .btn {
            background: #1a73e8;
            color: white;
            border: none;
            padding: 10px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 500;
            width: 100%;
            transition: background 0.2s;
        }
        
        .btn:hover {
            background: #0d62d9;
        }
        
        .btn.secondary {
            background: #f1f3f4;
            color: #333;
            margin-top: 8px;
        }
        
        .btn.secondary:hover {
            background: #e8eaed;
        }
        
        .status {
            margin-top: 12px;
            padding: 10px;
            border-radius: 4px;
            font-size: 12px;
            display: none;
            animation: fadeIn 0.3s;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        .success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            margin-top: 12px;
        }
        
        .stat-card {
            background: #f8f9fa;
            padding: 12px;
            border-radius: 6px;
            text-align: center;
        }
        
        .stat-value {
            font-size: 20px;
            font-weight: 600;
            color: #1a73e8;
        }
        
        .stat-label {
            font-size: 11px;
            color: #666;
            margin-top: 4px;
        }
        
        .footer {
            text-align: center;
            padding: 12px;
            font-size: 11px;
            color: #999;
            border-top: 1px solid #eee;
        }
        
        .toggle {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin: 12px 0;
        }
        
        .toggle-switch {
            position: relative;
            display: inline-block;
            width: 44px;
            height: 24px;
        }
        
        .toggle-switch input {
            opacity: 0;
            width: 0;
            height: 0;
        }
        
        .toggle-slider {
            position: absolute;
            cursor: pointer;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background-color: #ccc;
            transition: .4s;
            border-radius: 24px;
        }
        
        .toggle-slider:before {
            position: absolute;
            content: "";
            height: 16px;
            width: 16px;
            left: 4px;
            bottom: 4px;
            background-color: white;
            transition: .4s;
            border-radius: 50%;
        }
        
        input:checked + .toggle-slider {
            background-color: #1a73e8;
        }
        
        input:checked + .toggle-slider:before {
            transform: translateX(20px);
        }
        
        .privacy-note {
            font-size: 11px;
            color: #666;
            margin-top: 12px;
            padding: 8px;
            background: #f8f9fa;
            border-radius: 4px;
            line-height: 1.4;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Undo</h1>
        <p>Safer Email Assistant</p>
    </div>
    
    <div class="content">
        <!-- Settings Section -->
        <div class="section">
            <h3>🔐 API Configuration</h3>
            <input type="password" 
                   id="apiKey" 
                   class="api-key-input" 
                   placeholder="Enter your OpenAI API key">
            <button id="saveKey" class="btn">Save API Key</button>
            
            <div class="toggle">
                <span style="font-size: 13px;">Enable on LinkedIn</span>
                <label class="toggle-switch">
                    <input type="checkbox" id="toggleLinkedIn" checked>
                    <span class="toggle-slider"></span>
                </label>
            </div>
            
            <div class="toggle">
                <span style="font-size: 13px;">Enable on Gmail</span>
                <label class="toggle-switch">
                    <input type="checkbox" id="toggleGmail" checked>
                    <span class="toggle-slider"></span>
                </label>
            </div>
            
            <div id="status" class="status"></div>
        </div>
        
        <!-- Statistics Section -->
        <div class="section">
            <h3>📊 Your Stats</h3>
            <div class="stats-grid" id="statsGrid">
                <div class="stat-card">
                    <div class="stat-value" id="totalMessages">0</div>
                    <div class="stat-label">Messages Checked</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value" id="avgRisk">0%</div>
                    <div class="stat-label">Avg Risk</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value" id="highRisk">0</div>
                    <div class="stat-label">High Risk</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value" id="suggestions">0</div>
                    <div class="stat-label">Suggestions Used</div>
                </div>
            </div>
        </div>
        
        <!-- Actions Section -->
        <div class="section">
            <h3>⚡ Quick Actions</h3>
            <button id="testAnalysis" class="btn secondary">Test Analysis</button>
            <button id="viewDashboard" class="btn secondary">Open Dashboard</button>
            <button id="clearHistory" class="btn secondary" style="background: #fef2f2; color: #dc2626;">
                Clear Local Data
            </button>
        </div>
        
        <div class="privacy-note">
            🔒 Your API key is stored locally and never sent to our servers. 
            Message analysis happens via OpenAI API.
        </div>
    </div>
    
    <div class="footer">
        Undo v1.0 • <a href="#" id="viewDocs" style="color: #1a73e8; text-decoration: none;">Docs</a>
    </div>
    
    <script src="popup.js"></script>
</body>
</html>
EOF
echo -e "${GREEN}✓ Created popup.html${NC}"

# popup.js
cat > popup.js << 'EOF'
document.addEventListener('DOMContentLoaded', function() {
    // Load saved settings
    chrome.storage.local.get(['undoApiKey', 'enableGmail', 'enableLinkedIn'], function(result) {
        if (result.undoApiKey) {
            document.getElementById('apiKey').value = result.undoApiKey;
        }
        document.getElementById('toggleGmail').checked = result.enableGmail !== false;
        document.getElementById('toggleLinkedIn').checked = result.enableLinkedIn !== false;
    });
    
    // Load stats
    loadStats();
    
    // Save API key
    document.getElementById('saveKey').addEventListener('click', saveApiKey);
    
    // Save on Enter key
    document.getElementById('apiKey').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') saveApiKey();
    });
    
    // Toggle events
    document.getElementById('toggleGmail').addEventListener('change', function() {
        chrome.storage.local.set({ enableGmail: this.checked });
        showStatus(`${this.checked ? 'Enabled' : 'Disabled'} on Gmail`, 'success');
    });
    
    document.getElementById('toggleLinkedIn').addEventListener('change', function() {
        chrome.storage.local.set({ enableLinkedIn: this.checked });
        showStatus(`${this.checked ? 'Enabled' : 'Disabled'} on LinkedIn`, 'success');
    });
    
    // Test analysis
    document.getElementById('testAnalysis').addEventListener('click', function() {
        showStatus('Testing analysis... This is a demo.', 'success');
        
        // Update stats for demo
        const totalEl = document.getElementById('totalMessages');
        totalEl.textContent = parseInt(totalEl.textContent) + 1;
        
        setTimeout(() => {
            showStatus('Test complete! Try it in Gmail/LinkedIn.', 'success');
        }, 1000);
    });
    
    // View dashboard
    document.getElementById('viewDashboard').addEventListener('click', function() {
        chrome.tabs.create({ url: 'http://localhost:3000' });
    });
    
    // Clear history
    document.getElementById('clearHistory').addEventListener('click', function() {
        if (confirm('Clear all local data including API key?')) {
            chrome.storage.local.clear(function() {
                document.getElementById('apiKey').value = '';
                showStatus('All data cleared', 'success');
                loadStats(); // Reset stats
            });
        }
    });
    
    // View docs
    document.getElementById('viewDocs').addEventListener('click', function(e) {
        e.preventDefault();
        chrome.tabs.create({ 
            url: 'https://github.com/thartark/undo#readme' 
        });
    });
});

function saveApiKey() {
    const apiKey = document.getElementById('apiKey').value.trim();
    
    if (!apiKey) {
        showStatus('Please enter an API key', 'error');
        return;
    }
    
    if (!apiKey.startsWith('sk-')) {
        if (!confirm("This doesn't look like an OpenAI API key (should start with 'sk-'). Continue?")) {
            return;
        }
    }
    
    chrome.storage.local.set({ undoApiKey: apiKey }, function() {
        showStatus('API key saved successfully!', 'success');
        
        // Update stats to show API is ready
        document.getElementById('totalMessages').textContent = 'Ready';
        document.getElementById('avgRisk').textContent = 'API ✓';
    });
}

function showStatus(message, type) {
    const statusDiv = document.getElementById('status');
    statusDiv.textContent = message;
    statusDiv.className = `status ${type}`;
    statusDiv.style.display = 'block';
    
    setTimeout(() => {
        statusDiv.style.display = 'none';
    }, 3000);
}

async function loadStats() {
    try {
        // Try to get stats from server
        const response = await fetch('http://localhost:3000/api/stats');
        const stats = await response.json();
        
        document.getElementById('totalMessages').textContent = stats.totalMessages || '0';
        document.getElementById('avgRisk').textContent = stats.highRiskPercentage ? 
            `${parseFloat(stats.highRiskPercentage).toFixed(1)}%` : '0%';
        document.getElementById('highRisk').textContent = stats.highRiskCount || '0';
        document.getElementById('suggestions').textContent = stats.suggestionsUsed || '0';
        
    } catch (error) {
        // Server not running, use local storage stats
        chrome.storage.local.get(['messageCount', 'highRiskCount'], function(result) {
            document.getElementById('totalMessages').textContent = result.messageCount || '0';
            document.getElementById('highRisk').textContent = result.highRiskCount || '0';
            
            // Generate demo stats if none exist
            if (!result.messageCount) {
                const demoStats = generateDemoStats();
                document.getElementById('totalMessages').textContent = demoStats.total;
                document.getElementById('avgRisk').textContent = demoStats.avgRisk;
                document.getElementById('highRisk').textContent = demoStats.highRisk;
                document.getElementById('suggestions').textContent = demoStats.suggestions;
            }
        });
    }
}

function generateDemoStats() {
    return {
        total: Math.floor(Math.random() * 50) + 10,
        avgRisk: `${Math.floor(Math.random() * 40) + 10}%`,
        highRisk: Math.floor(Math.random() * 10),
        suggestions: Math.floor(Math.random() * 20)
    };
}

// Update stats every 30 seconds
setInterval(loadStats, 30000);
EOF
echo -e "${GREEN}✓ Created popup.js${NC}"

# background.js
cat > background.js << 'EOF'
console.log('Undo background script loaded');

// Listen for messages from content script
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.type === 'ANALYSIS_COMPLETE') {
        console.log('Analysis complete for:', request.url);
        
        // Store in local storage for stats
        chrome.storage.local.get(['messageCount', 'highRiskCount'], function(result) {
            const newCount = (result.messageCount || 0) + 1;
            const newHighRisk = (result.highRiskCount || 0) + 
                (request.riskLevel === 'high' ? 1 : 0);
            
            chrome.storage.local.set({
                messageCount: newCount,
                highRiskCount: newHighRisk
            });
        });
    }
    
    if (request.type === 'GET_API_KEY') {
        chrome.storage.local.get(['undoApiKey'], function(result) {
            sendResponse({ apiKey: result.undoApiKey });
        });
        return true; // Will respond asynchronously
    }
});

// Track active tab changes
chrome.tabs.onActivated.addListener((activeInfo) => {
    chrome.tabs.get(activeInfo.tabId, (tab) => {
        if (tab.url?.includes('mail.google.com') || tab.url?.includes('linkedin.com')) {
            console.log('Undo active on:', new URL(tab.url).hostname);
        }
    });
});
EOF
echo -e "${GREEN}✓ Created background.js${NC}"

# 2. Create Icon Files (PNG placeholders)
echo -e "\n${BLUE}[2/4] Creating Icon Files...${NC}"

# Create simple icon files (you can replace these with proper icons later)
convert_icon() {
    size=$1
    cat > "icons/icon${size}.png.base64" << 'EOF'

# This is a comment: Creating icon placeholder file
EOF
    
    # Instead of base64, let's create simple icon files using ImageMagick or fallback
    if command -v convert &> /dev/null; then
        # Create icon using ImageMagick
        convert -size ${size}x${size} xc:#1a73e8 \
                -fill white -draw "circle $((size/2)),$((size/2)) $((size/2)),$((size/4))" \
                -draw "line $((size/2)),$((size/2)) $((size/2)),$((size*3/4))" \
                "icons/icon${size}.png"
        echo -e "${GREEN}✓ Created icon${size}.png with ImageMagick${NC}"
    else
        # Fallback: create simple text file and rename
        echo "Placeholder icon ${size}x${size}" > "icons/icon${size}.txt"
        mv "icons/icon${size}.txt" "icons/icon${size}.png"
        echo -e "${YELLOW}⚠  Created placeholder icon${size}.png (install ImageMagick for better icons)${NC}"
    fi
}

# Generate icons
convert_icon 16
convert_icon 48
convert_icon 128

# 3. Create Node.js Server Files
echo -e "\n${BLUE}[3/4] Creating Node.js Server Files...${NC}"

mkdir -p server
cd server

# package.json
cat > package.json << 'EOF'
{
  "name": "undo-server",
  "version": "1.0.0",
  "description": "Backend server for Undo Chrome Extension",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "mongoose": "^7.0.0"
  },
  "devDependencies": {
    "nodemon": "^2.0.22"
  }
}
EOF
echo -e "${GREEN}✓ Created server/package.json${NC}"

# server.js
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage (replace with MongoDB for production)
let messages = [];
let stats = {
    totalMessages: 0,
    highRiskCount: 0,
    suggestionsUsed: 0
};

// API Routes
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        messagesCount: messages.length
    });
});

// Store a message
app.post('/api/messages', (req, res) => {
    try {
        const message = {
            id: Date.now().toString(),
            original: req.body.original?.substring(0, 500) || '',
            alternative: req.body.alternative || '',
            riskScore: req.body.riskScore || 0,
            riskLevel: req.body.riskLevel || 'low',
            timestamp: new Date().toISOString(),
            url: req.body.url || ''
        };
        
        messages.push(message);
        messages = messages.slice(-1000); // Keep only last 1000 messages
        
        // Update stats
        stats.totalMessages++;
        if (message.riskLevel === 'high') {
            stats.highRiskCount++;
        }
        
        console.log(`Stored message #${stats.totalMessages}`);
        res.status(201).json({ 
            success: true, 
            id: message.id,
            message: 'Message stored successfully'
        });
    } catch (error) {
        console.error('Error storing message:', error);
        res.status(500).json({ 
            error: 'Failed to store message',
            details: error.message 
        });
    }
});

// Get all messages
app.get('/api/messages', (req, res) => {
    const limit = parseInt(req.query.limit) || 50;
    res.json(messages.slice(-limit).reverse());
});

// Get statistics
app.get('/api/stats', (req, res) => {
    const highRiskPercentage = stats.totalMessages > 0 
        ? ((stats.highRiskCount / stats.totalMessages) * 100).toFixed(1)
        : '0.0';
    
    res.json({
        totalMessages: stats.totalMessages,
        highRiskCount: stats.highRiskCount,
        highRiskPercentage: highRiskPercentage,
        dailyAverage: calculateDailyAverage(),
        lastUpdated: new Date().toISOString()
    });
});

// Relationship graph data
app.get('/api/relationships', (req, res) => {
    // Extract domains from URLs
    const domains = {};
    messages.forEach(msg => {
        try {
            if (msg.url) {
                const url = new URL(msg.url);
                const domain = url.hostname.replace('www.', '');
                domains[domain] = (domains[domain] || 0) + 1;
            }
        } catch (e) {
            // Skip invalid URLs
        }
    });
    
    // Create nodes for D3.js graph
    const nodes = Object.keys(domains).map(domain => ({
        id: domain,
        group: 1,
        value: domains[domain],
        label: domain
    }));
    
    // Create links (simplified for demo)
    const links = [];
    if (nodes.length > 1) {
        links.push({
            source: nodes[0].id,
            target: nodes[nodes.length > 1 ? 1 : 0].id,
            value: 1
        });
    }
    
    res.json({ 
        nodes: nodes.slice(0, 10), // Limit to 10 nodes for demo
        links: links 
    });
});

// Helper function to calculate daily average
function calculateDailyAverage() {
    if (messages.length < 2) return '0.0';
    
    const firstDate = new Date(messages[0].timestamp);
    const lastDate = new Date(messages[messages.length - 1].timestamp);
    const days = Math.max(1, (lastDate - firstDate) / (1000 * 60 * 60 * 24));
    
    return (messages.length / days).toFixed(1);
}

// Dashboard HTML
app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Undo Dashboard</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    padding: 20px;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 20px;
                    padding: 40px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.1);
                }
                header {
                    text-align: center;
                    margin-bottom: 40px;
                }
                h1 {
                    color: #333;
                    font-size: 2.5em;
                    margin-bottom: 10px;
                }
                .subtitle {
                    color: #666;
                    font-size: 1.2em;
                }
                .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                    gap: 20px;
                    margin-bottom: 40px;
                }
                .stat-card {
                    background: #f8f9fa;
                    padding: 25px;
                    border-radius: 15px;
                    text-align: center;
                    transition: transform 0.3s;
                }
                .stat-card:hover {
                    transform: translateY(-5px);
                }
                .stat-value {
                    font-size: 2.5em;
                    font-weight: bold;
                    color: #1a73e8;
                    margin-bottom: 10px;
                }
                .stat-label {
                    color: #666;
                    font-size: 0.9em;
                }
                .message-list {
                    background: #f8f9fa;
                    border-radius: 15px;
                    padding: 20px;
                    margin-top: 20px;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                }
                th, td {
                    padding: 15px;
                    text-align: left;
                    border-bottom: 1px solid #e0e0e0;
                }
                th {
                    background: #e8f0fe;
                    color: #1a73e8;
                    font-weight: 600;
                }
                .risk-high { color: #dc3545; font-weight: bold; }
                .risk-medium { color: #ffc107; font-weight: bold; }
                .risk-low { color: #28a745; font-weight: bold; }
                .refresh-btn {
                    background: #1a73e8;
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    border-radius: 8px;
                    cursor: pointer;
                    font-size: 1em;
                    margin: 20px 0;
                    transition: background 0.3s;
                }
                .refresh-btn:hover {
                    background: #0d62d9;
                }
                footer {
                    text-align: center;
                    margin-top: 40px;
                    color: #999;
                    font-size: 0.9em;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <header>
                    <h1>📊 Undo Analytics Dashboard</h1>
                    <p class="subtitle">Real-time email safety statistics and message history</p>
                </header>
                
                <div class="stats-grid" id="statsGrid">
                    <!-- Stats will be loaded here -->
                </div>
                
                <button class="refresh-btn" onclick="loadData()">🔄 Refresh Data</button>
                
                <div class="message-list">
                    <h2 style="margin-bottom: 20px;">Recent Messages</h2>
                    <table>
                        <thead>
                            <tr>
                                <th>Time</th>
                                <th>Risk</th>
                                <th>Score</th>
                                <th>Domain</th>
                                <th>Preview</th>
                            </tr>
                        </thead>
                        <tbody id="messagesBody">
                            <tr><td colspan="5" style="text-align: center;">Loading messages...</td></tr>
                        </tbody>
                    </table>
                </div>
                
                <footer>
                    <p>Undo Chrome Extension v1.0.0 • Server running on port ${PORT}</p>
                    <p>API available at: /api/health, /api/messages, /api/stats, /api/relationships</p>
                </footer>
            </div>
            
            <script>
                async function loadData() {
                    try {
                        // Load stats
                        const statsRes = await fetch('/api/stats');
                        const stats = await statsRes.json();
                        
                        document.getElementById('statsGrid').innerHTML = \`
                            <div class="stat-card">
                                <div class="stat-value">\${stats.totalMessages}</div>
                                <div class="stat-label">Total Messages</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-value">\${stats.highRiskPercentage}%</div>
                                <div class="stat-label">High Risk Rate</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-value">\${stats.highRiskCount}</div>
                                <div class="stat-label">High Risk Messages</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-value">\${stats.dailyAverage}</div>
                                <div class="stat-label">Avg per Day</div>
                            </div>
                        \`;
                        
                        // Load messages
                        const messagesRes = await fetch('/api/messages?limit=10');
                        const messages = await messagesRes.json();
                        
                        const tbody = document.getElementById('messagesBody');
                        if (messages.length === 0) {
                            tbody.innerHTML = '<tr><td colspan="5" style="text-align: center;">No messages yet</td></tr>';
                        } else {
                            tbody.innerHTML = messages.map(msg => \`
                                <tr>
                                    <td>\${new Date(msg.timestamp).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</td>
                                    <td class="risk-\${msg.riskLevel}">\${msg.riskLevel.toUpperCase()}</td>
                                    <td>\${msg.riskScore}</td>
                                    <td>\${extractDomain(msg.url)}</td>
                                    <td title="\${msg.original}">\${msg.original.substring(0, 40)}...</td>
                                </tr>
                            \`).join('');
                        }
                        
                    } catch (error) {
                        console.error('Error loading data:', error);
                        document.getElementById('statsGrid').innerHTML = \`
                            <div class="stat-card" style="grid-column: 1 / -1;">
                                <div class="stat-value">⚠️</div>
                                <div class="stat-label">Error loading data. Check server connection.</div>
                            </div>
                        \`;
                    }
                }
                
                function extractDomain(url) {
                    if (!url) return 'Unknown';
                    try {
                        return new URL(url).hostname;
                    } catch (e) {
                        return url.length > 20 ? url.substring(0, 20) + '...' : url;
                    }
                }
                
                // Load data on page load
                loadData();
                
                // Auto-refresh every 30 seconds
                setInterval(loadData, 30000);
            </script>
        </body>
        </html>
    `);
});

// Start server
app.listen(PORT, () => {
    console.log(\`
    ╔══════════════════════════════════════════╗
    ║          Undo Server Started!            ║
    ╚══════════════════════════════════════════╝
    🌐 Dashboard: http://localhost:\${PORT}
    📡 API Health: http://localhost:\${PORT}/api/health
    📊 API Stats: http://localhost:\${PORT}/api/stats
    💾 API Messages: http://localhost:\${PORT}/api/messages
    🕸️ API Relationships: http://localhost:\${PORT}/api/relationships
    
    Server running on port \${PORT}
    Press Ctrl+C to stop
    \`);
});
EOF
echo -e "${GREEN}✓ Created server/server.js${NC}"

cd ..

# 4. Create README and Installation Script
echo -e "\n${BLUE}[4/4] Creating Documentation...${NC}"

# README.md
cat > README.md << 'EOF'
# Undo - Safer Email Assistant 🛡️

A Chrome extension that uses AI to analyze and improve email/message safety in real-time on Gmail and LinkedIn.

## 🚀 Quick Start

### 1. Install Chrome Extension
```bash
# Load the extension in Chrome:
# 1. Open Chrome → chrome://extensions/
# 2. Enable "Developer mode" (top-right)
# 3. Click "Load unpacked"
# 4. Select this 'undo' folder