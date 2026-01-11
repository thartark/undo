document.addEventListener('DOMContentLoaded', function() {
    console.log('Popup loaded');
    
    // Load saved token
    chrome.storage.local.get(['undoHFToken'], function(result) {
        console.log('Loaded token from storage');
        if (result.undoHFToken) {
            document.getElementById('tokenInput').value = result.undoHFToken;
        }
    });
    
    // Save token
    document.getElementById('saveBtn').addEventListener('click', function() {
        const token = document.getElementById('tokenInput').value.trim();
        
        if (!token) {
            showStatus('Please enter a token', 'error');
            return;
        }
        
        if (!token.startsWith('hf_')) {
            showStatus('Token must start with "hf_"', 'error');
            return;
        }
        
        chrome.storage.local.set({ undoHFToken: token }, function() {
            console.log('Token saved:', token.substring(0, 10) + '...');
            showStatus('✅ Token saved!', 'success');
            
            // Notify content scripts
            chrome.tabs.query({}, function(tabs) {
                tabs.forEach(function(tab) {
                    if (tab.url && tab.url.includes('mail.google.com')) {
                        chrome.tabs.sendMessage(tab.id, {
                            type: 'TOKEN_UPDATED',
                            token: token
                        }).catch(function() {
                            // Tab might not be ready
                        });
                    }
                });
            });
        });
    });
});

function showStatus(message, type) {
    const status = document.getElementById('status');
    status.textContent = message;
    status.className = 'status ' + type;
    status.style.display = 'block';
    setTimeout(function() {
        status.style.display = 'none';
    }, 3000);
}
