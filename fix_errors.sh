#!/bin/bash
cd ~/code/undo

echo "🔧 Fixing all syntax errors..."
echo "=============================="

# 1. Check and fix manifest.json
echo "📄 Checking manifest.json..."
if python3 -m json.tool manifest.json > /dev/null 2>&1; then
    echo "✅ manifest.json is valid JSON"
else
    echo "❌ Fixing manifest.json..."
    cat > manifest.json << 'MANIFEST'
{
  "manifest_version": 3,
  "name": "Undo",
  "version": "1.0",
  "description": "Safer email assistant",
  "permissions": ["storage"],
  "host_permissions": ["https://mail.google.com/*"],
  "content_scripts": [{
    "matches": ["https://mail.google.com/*"],
    "js": ["content.js"],
    "css": ["content.css"]
  }],
  "action": {
    "default_popup": "popup.html"
  }
}
MANIFEST
    echo "✅ Fixed manifest.json"
fi

# 2. Ensure content.css is valid
echo ""
echo "🎨 Checking content.css..."
if grep -q "@keyframes" content.css; then
    echo "✅ content.css has animations"
else
    echo "⚠️  Adding animations to content.css..."
    cat >> content.css << 'CSS'

/* Animation for spinner */
@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* Animation for popup */
@keyframes slideIn {
    from { opacity: 0; transform: translateX(20px); }
    to { opacity: 1; transform: translateX(0); }
}
CSS
fi

# 3. Create a test HTML to verify
cat > test_extension.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial; padding: 20px; }
        .test-box { border: 2px solid #1a73e8; padding: 20px; margin: 20px 0; }
        button { padding: 10px 20px; background: #1a73e8; color: white; border: none; border-radius: 4px; }
    </style>
</head>
<body>
    <h2>Undo Extension Test</h2>
    <div class="test-box">
        <p>If extension loads correctly, you should see in Gmail Console:</p>
        <ul>
            <li>"Undo: Extension loaded"</li>
            <li>"Undo: Token loaded Yes"</li>
            <li>"Undo: Analyzing text" when typing</li>
        </ul>
        <button onclick="testToken()">Test Token Storage</button>
    </div>
    
    <script>
    function testToken() {
        chrome.storage.local.get(['undoHFToken'], function(result) {
            alert('Token: ' + (result.undoHFToken || 'Not found'));
        });
    }
    </script>
</body>
</html>
HTML

echo "✅ Created test page: test_extension.html"
echo ""
echo "📋 Next steps:"
echo "1. Go to chrome://extensions/"
echo "2. Click 🔄 Refresh on Undo extension"
echo "3. Refresh Gmail"
echo "4. Type in compose box"
echo ""
echo "🎯 Expected behavior:"
echo "   • Loading spinner at top-right"
echo "   • Safety popup at top-right after 2 seconds"
echo "   • Gmail layout should NOT break"
echo ""
echo "🔄 If still issues, open: file://$(pwd)/test_extension.html"
