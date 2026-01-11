#!/bin/bash
cd ~/code/undo

echo "🧹 Cleaning up folder structure..."
echo "Current location: $(pwd)"
echo ""

# Check what we have
if [ -d "undo" ]; then
    echo "✅ Found inner 'undo' folder"
    echo "Contents of inner folder:"
    ls -la undo/
    echo ""
    
    # Move everything from inner folder to current folder
    echo "🚚 Moving files from inner folder to parent..."
    mv undo/* . 2>/dev/null
    mv undo/.* . 2>/dev/null 2>/dev/null || true  # Ignore errors for . and ..
    
    # Remove the now-empty inner folder
    rmdir undo/
    
    echo "✅ Moved all files!"
else
    echo "❌ No inner 'undo' folder found"
    echo "Current files:"
    ls -la
fi

echo ""
echo "📁 Final structure:"
ls -la
echo ""

# Check for critical files
echo "🔍 Checking for essential files:"
[ -f "manifest.json" ] && echo "✅ manifest.json" || echo "❌ MISSING manifest.json"
[ -f "popup.js" ] && echo "✅ popup.js" || echo "❌ MISSING popup.js"
[ -f "content.js" ] && echo "✅ content.js" || echo "❌ MISSING content.js"
[ -f "popup.html" ] && echo "✅ popup.html" || echo "❌ MISSING popup.html"
[ -d "icons" ] && echo "✅ icons folder" || echo "⚠️  No icons folder (will need to create)"

echo ""
echo "📋 Path to use in Chrome:"
echo "   $(pwd)"
pwd | pbcopy
echo "✅ Path copied to clipboard!"
echo ""
echo "🔄 Next steps:"
echo "1. Go to chrome://extensions/"
echo "2. Remove the old Undo extension"
echo "3. Click 'Load unpacked'"
echo "4. Select THIS folder: $(pwd)"
echo "5. Add your Hugging Face token again"