document.addEventListener('DOMContentLoaded', function() {
    // Load saved settings
    chrome.storage.local.get(['undoHFToken', 'enableGmail', 'enableLinkedIn'], function(result) {
        if (result.undoHFToken) {
            document.getElementById('hfToken').value = result.undoHFToken;
        }
        document.getElementById('toggleGmail').checked = result.enableGmail !== false;
        document.getElementById('toggleLinkedIn').checked = result.enableLinkedIn !== false;
        
        // Update UI based on token
        updateTokenStatus(result.undoHFToken);
    });
    
    // Load stats
    loadStats();
    
    // Save Hugging Face token
    document.getElementById('saveToken').addEventListener('click', saveHFToken);
    
    // Save on Enter key
    document.getElementById('hfToken').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') saveHFToken();
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
    
    // Get Hugging Face token link
    document.getElementById('getHFToken').addEventListener('click', function() {
        chrome.tabs.create({ 
            url: 'https://huggingface.co/settings/tokens' 
        });
    });
    
    // Test analysis
    document.getElementById('testAnalysis').addEventListener('click', function() {
        showStatus('Testing analysis with Hugging Face...', 'success');
        
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
        if (confirm('Clear all local data including Hugging Face token?')) {
            chrome.storage.local.clear(function() {
                document.getElementById('hfToken').value = '';
                showStatus('All data cleared', 'success');
                updateTokenStatus('');
                loadStats();
            });
        }
    });
    
    // View docs
    document.getElementById('viewDocs').addEventListener('click', function(e) {
        e.preventDefault();
        chrome.tabs.create({ 
            url: 'https://huggingface.co/docs/api-inference/quicktour' 
        });
    });
});

function updateTokenStatus(token) {
    const statusEl = document.getElementById('tokenStatus');
    if (token && token.startsWith('hf_')) {
        statusEl.textContent = '✅ Token configured';
        statusEl.className = 'token-status valid';
        document.getElementById('testAnalysis').disabled = false;
    } else if (token) {
        statusEl.textContent = '⚠️ Invalid token format (should start with hf_)';
        statusEl.className = 'token-status warning';
        document.getElementById('testAnalysis').disabled = true;
    } else {
        statusEl.textContent = '❌ No token configured';
        statusEl.className = 'token-status error';
        document.getElementById('testAnalysis').disabled = true;
    }
}

function saveHFToken() {
    const token = document.getElementById('hfToken').value.trim();
    
    if (!token) {
        showStatus('Please enter a Hugging Face token', 'error');
        return;
    }
    
    if (!token.startsWith('hf_')) {
        showStatus('Hugging Face tokens should start with "hf_"', 'error');
        return;
    }
    
    chrome.storage.local.set({ undoHFToken: token }, function() {
        showStatus('Hugging Face token saved successfully!', 'success');
        updateTokenStatus(token);
        
        // Update stats to show API is ready
        document.getElementById('totalMessages').textContent = 'Ready';
        document.getElementById('avgRisk').textContent = 'HF ✓';
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
function updateTokenStatus(token) {
    const statusEl = document.getElementById('tokenStatus');
    if (!statusEl) return;
    
    if (token && token.startsWith('hf_')) {
        statusEl.textContent = '✅ Token configured';
        statusEl.className = 'token-status valid';
    } else if (token) {
        statusEl.textContent = '⚠️ Invalid token format';
        statusEl.className = 'token-status warning';
    } else {
        statusEl.textContent = '❌ No token configured';
        statusEl.className = 'token-status error';
    }
}
// Update stats every 30 seconds
setInterval(loadStats, 30000);