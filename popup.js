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
