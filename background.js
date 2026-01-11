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
