document.addEventListener('DOMContentLoaded', function() {
    console.log('Undo popup loaded');
    
    // Load saved token
    chrome.storage.local.get(['undoHFToken'], function(result) {
        console.log('Loaded from storage:', result.undoHFToken);
        const tokenInput = document.getElementById('hfToken');
        if (tokenInput && result.undoHFToken) {
            tokenInput.value = result.undoHFToken;
            updateStatus('✅ Token loaded from storage', 'success');
        }
    });
    
    // Save token
    document.getElementById('saveToken').addEventListener('click', saveToken);
    
    // Get token link
    document.getElementById('getTokenLink').addEventListener('click', function(e) {
        e.preventDefault();
        chrome.tabs.create({ url: 'https://huggingface.co/settings/tokens' });
    });
});

function saveToken() {
    const tokenInput = document.getElementById('hfToken');
    const token = tokenInput.value.trim();
    
    console.log('Saving token:', token ? `${token.substring(0, 10)}...` : 'empty');
    
    if (!token) {
        updateStatus('❌ Please enter a token', 'error');
        return;
    }
    
    if (!token.startsWith('hf_')) {
        updateStatus('❌ Token must start with "hf_"', 'error');
        return;
    }
    
    // Save to storage
    chrome.storage.local.set({ undoHFToken: token }, function() {
        console.log('Token saved to storage');
        updateStatus('✅ Token saved successfully!', 'success');
        
        // CRITICAL: Notify all Gmail/LinkedIn tabs
        chrome.tabs.query({}, function(tabs) {
            let notified = 0;
            tabs.forEach(function(tab) {
                if (tab.url && (tab.url.includes('mail.google.com') || tab.url.includes('linkedin.com'))) {
                    console.log('Notifying tab:', tab.url);
                    chrome.tabs.sendMessage(tab.id, {
                        type: 'TOKEN_UPDATED',
                        token: token,
                        timestamp: Date.now()
                    }).then(() => {
                        notified++;
                        console.log('Tab notified successfully');
                    }).catch(err => {
                        console.log('Tab not ready for messages, reloading it');
                        chrome.tabs.reload(tab.id);
                    });
                }
            });
            console.log(`Notified ${notified} tabs`);
        });
        
        // Also update popup status
        document.getElementById('tokenStatus').textContent = '✅ Token active - AI enabled!';
        document.getElementById('tokenStatus').style.color = '#4CAF50';
    });
}

function updateStatus(message, type) {
    const statusDiv = document.getElementById('status');
    if (!statusDiv) return;
    
    statusDiv.textContent = message;
    statusDiv.className = type;
    statusDiv.style.display = 'block';
    
    setTimeout(() => {
        statusDiv.style.display = 'none';
    }, 3000);
}
