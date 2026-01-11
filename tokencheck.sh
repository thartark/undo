# Run this quick check script
cd ~/code/undo
cat > check_token.js << 'EOF'
// Save this as check_token.js and run with node
const fs = require('fs');
const path = require('path');

// Check popup.js for the save function
const popupJs = fs.readFileSync('popup.js', 'utf8');
if (popupJs.includes('chrome.storage.local.set({ undoHFToken: token }')) {
  console.log('✅ popup.js has correct save function');
} else {
  console.log('❌ popup.js missing save function');
}

// Check content.js for token loading
const contentJs = fs.readFileSync('content.js', 'utf8');
if (contentJs.includes('chrome.storage.local.get([\'undoHFToken\']')) {
  console.log('✅ content.js loads token from storage');
} else {
  console.log('❌ content.js missing token loading');
}

console.log('\n📋 To manually check token in Chrome:');
console.log('1. Click Undo extension icon');
console.log('2. Right-click on popup → "Inspect"');
console.log('3. In Console tab, paste:');
console.log('   chrome.storage.local.get([\'undoHFToken\'], r => console.log(\'Token:\', r.undoHFToken))');
EOF

node check_token.js