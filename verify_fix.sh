#!/bin/bash
echo "🔍 VERIFYING FIXED EXTENSION"
echo "============================="

# Check critical files
echo "📁 Checking files:"
[ -f "manifest.json" ] && echo "✅ manifest.json exists" || echo "❌ manifest.json missing"
[ -f "popup.js" ] && echo "✅ popup.js exists" || echo "❌ popup.js missing"
[ -f "content.js" ] && echo "✅ content.js exists" || echo "❌ content.js missing"

echo ""
echo "🔍 Checking token handling in files:"

# Check if popup.js has the FIXED save function
if grep -q "chrome.tabs.query" popup.js; then
    echo "✅ popup.js has tab notification (FIXED)"
else
    echo "❌ popup.js missing tab notification"
fi

# Check if content.js has message listener
if grep -q "TOKEN_UPDATED" content.js; then
    echo "✅ content.js listens for token updates"
else
    echo "❌ content.js missing token listener"
fi

echo ""
echo "📋 YOUR NEXT STEPS:"
echo "1. chrome://extensions/ → Remove old Undo"
echo "2. Click 'Load unpacked'"
echo "3. Select: $(pwd)"
echo "4. Click Undo icon → Add token → Save"
echo "5. Open Gmail → Compose → Type test message"
echo ""
echo "💡 Test message to use:"
echo '   "This is URGENT!!! I HATE waiting!!!"'
echo ""
echo "🔄 Path for Chrome:"
echo "   $(pwd)"
