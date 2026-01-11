#!/bin/bash
echo "🧪 TESTING THE FIX"
echo "=================="
echo ""
echo "1. Checking file sizes:"
echo "   content.js: $(wc -l < content.js) lines"
echo "   content.css: $(wc -l < content.css) lines"
echo "   manifest.json: $(wc -l < manifest.json) lines"
echo ""
echo "2. Checking for duplicates in content.js:"
duplicates=$(grep -c "// Undo Extension" content.js)
if [ "$duplicates" -eq 1 ]; then
    echo "   ✅ Only one copy of content.js"
else
    echo "   ❌ Found $duplicates copies - removing extras..."
    # Keep only the first occurrence
    awk '/\/\/ Undo Extension/{if(!p){p=1; print; next}} p' content.js > temp && mv temp content.js
fi
echo ""
echo "3. Syntax check:"
if node -c content.js 2>/dev/null; then
    echo "   ✅ content.js has valid JavaScript syntax"
else
    echo "   ❌ JavaScript syntax error"
fi
echo ""
echo "🔄 To apply fix:"
echo "1. Go to chrome://extensions/"
echo "2. Click 🔄 Refresh on Undo extension"
echo "3. Refresh Gmail (Cmd+R)"
echo "4. Test with: 'This SUCKS!!!'"
echo ""
echo "🎯 Should see:"
echo "   • Loading spinner at top-right"
echo "   • Safety popup at top-right after 2 seconds"
echo "   • No Gmail layout issues"
