document.addEventListener('DOMContentLoaded', function() {
  // Get elements
  const undoBtn = document.getElementById('undoBtn');
  const redoBtn = document.getElementById('redoBtn');
  const uppercaseBtn = document.getElementById('uppercaseBtn');
  const lowercaseBtn = document.getElementById('lowercaseBtn');
  const wordCountEl = document.getElementById('wordCount');
  const charCountEl = document.getElementById('charCount');
  const historyList = document.getElementById('historyList');
  
  // Update stats
  function updateStats() {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      chrome.tabs.sendMessage(tabs[0].id, {action: "getStats"}, function(response) {
        if (response) {
          wordCountEl.textContent = response.words;
          charCountEl.textContent = response.chars;
        }
      });
    });
  }
  
  // Send command to content script
  function sendCommand(command, data = {}) {
    chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
      chrome.tabs.sendMessage(tabs[0].id, {
        action: "command",
        command: command,
        data: data
      }, function(response) {
        if (response && response.success) {
          updateStats();
          loadHistory();
        }
      });
    });
  }
  
  // Load history
  function loadHistory() {
    chrome.storage.local.get(['textHistory'], function(result) {
      const history = result.textHistory || [];
      historyList.innerHTML = '';
      
      history.slice(-10).reverse().forEach((item, index) => {
        const div = document.createElement('div');
        div.className = 'history-item';
        div.textContent = item.text.substring(0, 50) + (item.text.length > 50 ? '...' : '');
        div.title = `Restore: ${item.text}`;
        div.onclick = () => sendCommand('restore', {text: item.text});
        historyList.appendChild(div);
      });
    });
  }
  
  // Button event listeners
  undoBtn.addEventListener('click', () => sendCommand('undo'));
  redoBtn.addEventListener('click', () => sendCommand('redo'));
  uppercaseBtn.addEventListener('click', () => sendCommand('transform', {type: 'uppercase'}));
  lowercaseBtn.addEventListener('click', () => sendCommand('transform', {type: 'lowercase'}));
  
  // Initial load
  updateStats();
  loadHistory();
  
  // Update stats every 2 seconds
  setInterval(updateStats, 2000);
});
