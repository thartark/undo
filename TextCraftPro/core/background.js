// Background service worker for TextCraft Pro

// Handle extension installation
chrome.runtime.onInstalled.addListener(function(details) {
  if (details.reason === 'install') {
    // Initialize storage
    chrome.storage.local.set({
      textHistory: [],
      settings: {
        autoSave: true,
        maxHistory: 100,
        darkMode: false
      }
    });
    
    // Show welcome page
    chrome.tabs.create({
      url: chrome.runtime.getURL('welcome.html')
    });
  }
});

// Handle messages from content scripts
chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
  if (request.action === "saveText") {
    chrome.storage.local.get(['textHistory'], function(result) {
      const history = result.textHistory || [];
      history.push({
        text: request.text,
        timestamp: new Date().toISOString(),
        url: sender.tab ? sender.tab.url : 'unknown'
      });
      
      // Limit history size
      if (history.length > 100) {
        history = history.slice(-100);
      }
      
      chrome.storage.local.set({textHistory: history});
    });
  }
  sendResponse({success: true});
});
