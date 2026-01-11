// History stack for undo/redo
let historyStack = [];
let historyIndex = -1;
let currentText = '';

// Initialize
function init() {
  // Listen for messages from popup
  chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
    if (request.action === "command") {
      handleCommand(request.command, request.data, sendResponse);
      return true;
    } else if (request.action === "getStats") {
      sendResponse(getTextStats());
      return true;
    }
  });
  
  // Add textarea/input listeners for auto-save
  document.addEventListener('input', handleTextChange, true);
  document.addEventListener('change', handleTextChange, true);
  
  // Initialize history from storage
  chrome.storage.local.get(['textHistory'], function(result) {
    if (result.textHistory) {
      historyStack = result.textHistory;
      historyIndex = historyStack.length - 1;
    }
  });
}

// Handle text changes
function handleTextChange(e) {
  if (e.target.tagName === 'TEXTAREA' || e.target.tagName === 'INPUT') {
    saveToHistory(e.target.value);
  }
}

// Save text to history
function saveToHistory(text) {
  if (text === currentText) return;
  
  currentText = text;
  historyStack.push({
    text: text,
    timestamp: new Date().toISOString()
  });
  
  // Limit history size
  if (historyStack.length > 100) {
    historyStack = historyStack.slice(-100);
  }
  
  historyIndex = historyStack.length - 1;
  
  // Save to storage
  chrome.storage.local.set({textHistory: historyStack});
}

// Get active text element
function getActiveElement() {
  const active = document.activeElement;
  if (active.tagName === 'TEXTAREA' || active.tagName === 'INPUT') {
    return active;
  }
  // Try to find any textarea or contenteditable
  const textarea = document.querySelector('textarea, [contenteditable="true"]');
  return textarea || null;
}

// Handle commands from popup
function handleCommand(command, data, callback) {
  const element = getActiveElement();
  if (!element) {
    callback({success: false, error: 'No text element found'});
    return;
  }
  
  switch(command) {
    case 'undo':
      if (historyIndex > 0) {
        historyIndex--;
        const prevText = historyStack[historyIndex].text;
        element.value = prevText;
        element.dispatchEvent(new Event('input', {bubbles: true}));
        callback({success: true});
      }
      break;
      
    case 'redo':
      if (historyIndex < historyStack.length - 1) {
        historyIndex++;
        const nextText = historyStack[historyIndex].text;
        element.value = nextText;
        element.dispatchEvent(new Event('input', {bubbles: true}));
        callback({success: true});
      }
      break;
      
    case 'transform':
      if (data.type === 'uppercase') {
        element.value = element.value.toUpperCase();
      } else if (data.type === 'lowercase') {
        element.value = element.value.toLowerCase();
      }
      element.dispatchEvent(new Event('input', {bubbles: true}));
      callback({success: true});
      break;
      
    case 'restore':
      element.value = data.text;
      element.dispatchEvent(new Event('input', {bubbles: true}));
      callback({success: true});
      break;
      
    default:
      callback({success: false, error: 'Unknown command'});
  }
}

// Get text statistics
function getTextStats() {
  const element = getActiveElement();
  if (!element) return {words: 0, chars: 0};
  
  const text = element.value || '';
  const words = text.trim() ? text.trim().split(/\s+/).length : 0;
  const chars = text.length;
  
  return {words, chars};
}

// Initialize when page loads
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
