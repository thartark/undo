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
