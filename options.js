document.getElementById('save').onclick = function() {
    const settings = {
        autoSave: document.getElementById('autoSave').checked,
        maxHistory: parseInt(document.getElementById('maxHistory').value)
    };
    chrome.storage.local.set({settings: settings}, function() {
        alert('Settings saved!');
    });
};

// Load saved settings
chrome.storage.local.get(['settings'], function(result) {
    if (result.settings) {
        document.getElementById('autoSave').checked = result.settings.autoSave;
        document.getElementById('maxHistory').value = result.settings.maxHistory;
    }
});
