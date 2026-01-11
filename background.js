console.log('[Undo] Background service worker started');

// Listen for messages
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    console.log('[Undo] Background received:', request.action || request.type);
    
    if (request.action === 'openPopup') {
        chrome.action.openPopup();
        sendResponse({ success: true });
    }
    
    if (request.type === 'ANALYSIS_COMPLETE') {
        // Update stats
        chrome.storage.local.get(['messageCount'], (result) => {
            const count = (result.messageCount || 0) + 1;
            chrome.storage.local.set({ messageCount: count });
            console.log(`[Undo] Message ${count} analyzed`);
        });
    }
    
    return true;
});

// Track installation
chrome.runtime.onInstalled.addListener(() => {
    console.log('[Undo] Extension installed');
    chrome.storage.local.set({ undoHFToken: null, messageCount: 0 });
});
