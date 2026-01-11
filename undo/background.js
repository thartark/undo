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
// Listen for messages to open popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.action === 'openPopup') {
        chrome.action.openPopup();
    }
});