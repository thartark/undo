#!/bin/bash
# test_extension.sh
echo "🧪 Testing TextCraft Pro Extension"
echo "=================================="

# Check if extension files exist
if [ ! -f "TextCraftPro/core/manifest.json" ]; then
    echo "Error: Core extension not found. Run ./01_install_basic.sh first."
    exit 1
fi

echo "1. Validating manifest.json..."
python3 -m json.tool TextCraftPro/core/manifest.json > /dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ manifest.json is valid JSON"
else
    echo "   ❌ manifest.json has JSON errors"
fi

echo ""
echo "2. Checking required files..."
REQUIRED_FILES=("manifest.json" "popup.html" "popup.js" "content.js" "background.js")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "TextCraftPro/core/$file" ]; then
        echo "   ✅ $file exists"
    else
        echo "   ❌ $file missing"
    fi
done

echo ""
echo "3. Checking file sizes..."
echo "   manifest.json: $(wc -l < TextCraftPro/core/manifest.json) lines"
echo "   content.js: $(wc -l < TextCraftPro/core/content.js) lines"
echo "   popup.js: $(wc -l < TextCraftPro/core/popup.js) lines"

echo ""
echo "4. Opening test page..."
if command -v xdg-open &> /dev/null; then
    xdg-open TextCraftPro/core/test.html 2>/dev/null &
elif command -v open &> /dev/null; then
    open TextCraftPro/core/test.html 2>/dev/null &
else
    echo "   Open TextCraftPro/core/test.html in your browser"
fi

echo ""
echo "5. Starting simple HTTP server for testing..."
echo "   Press Ctrl+C to stop the server"
echo "   Then visit: http://localhost:8000/core/test.html"
cd TextCraftPro && python3 -m http.server 8000