#!/bin/bash
# Save as: install_mac.sh

echo "🍎 Mac Chrome Extension Installer"
echo "================================="

# Get current directory
EXTENSION_PATH=$(pwd)
echo "📁 Extension location:"
echo "$EXTENSION_PATH"
echo ""

# Copy path to clipboard
echo "$EXTENSION_PATH" | pbcopy
echo "📋 Path copied to clipboard!"
echo ""

# Check if Chrome is installed
if [ ! -d "/Applications/Google Chrome.app" ]; then
    echo "❌ Google Chrome not found in Applications"
    echo "Download Chrome from: https://www.google.com/chrome/"
    exit 1
fi

# Verify required files
echo "🔍 Checking files..."
required_files=("manifest.json" "popup.html" "popup.js" "content.js" "content.css" "background.js")
missing_files=()

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "❌ Missing files:"
    for file in "${missing_files[@]}"; do
        echo "   - $file"
    done
    echo ""
    echo "Run: ls -la to see what files you have"
    exit 1
fi

echo "✅ All required files found!"
echo ""

# Create icons if missing
echo "🎨 Checking icons..."
if [ ! -d "icons" ]; then
    mkdir -p icons
    echo "Created icons directory"
fi

# Create simple icons using sips (built-in Mac tool)
create_icon() {
    size=$1
    if [ ! -f "icons/icon${size}.png" ]; then
        # Create a simple blue square with white U
        convert -size ${size}x${size} xc:#1a73e8 \
                -fill white -font "Helvetica-Bold" -pointsize $((size/2)) \
                -gravity center -annotate 0 "U" \
                "icons/icon${size}.png" 2>/dev/null || \
        # Fallback: download placeholder
        curl -s -o "icons/icon${size}.png" "https://via.placeholder.com/${size}/1a73e8/FFFFFF?text=U" || \
        # Last resort: create text file
        echo "placeholder" > "icons/icon${size}.png"
        echo "✅ Created icon${size}.png"
    fi
}

# Check if ImageMagick is installed for convert command
if ! command -v convert &> /dev/null; then
    echo "⚠️  Install ImageMagick for better icons:"
    echo "   brew install imagemagick"
    echo ""
    echo "Using placeholder icons for now..."
fi

for size in 16 48 128; do
    create_icon $size
done

echo ""
echo "🚀 READY TO INSTALL!"
echo "==================="
echo ""
echo "Follow these steps:"
echo ""
echo "1. Open Chrome (press Enter to open now, or skip with 'n'):"
read -p "   Open Chrome? [Y/n]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "   OK, open Chrome manually"
else
    echo "   Opening Chrome..."
    open -a "Google Chrome"
fi

echo ""
echo "2. In Chrome, type this in the address bar:"
echo "   🔗 chrome://extensions/"
echo ""
echo "3. Enable 'Developer mode' (toggle in top-right)"
echo ""
echo "4. Click 'Load unpacked' button"
echo ""
echo "5. Press ⌘ + Shift + G to open 'Go to folder' dialog"
echo "   Paste this path:"
echo "   📋 $EXTENSION_PATH"
echo "   (already copied to your clipboard)"
echo ""
echo "6. Press Enter, then click 'Open'"
echo ""
echo "7. The extension should appear! Pin it by clicking the puzzle piece 🧩"
echo "   then click the pin icon next to 'Undo'"
echo ""

# Offer to open extensions page directly
read -p "Open Chrome extensions page now? [Y/n]: " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "OK, you can open it manually"
else
    echo "Opening chrome://extensions..."
    open -a "Google Chrome" "chrome://extensions"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "Next steps:"
echo "1. Refresh any open Gmail or LinkedIn tabs"
echo "2. Click the Undo extension icon (blue U)"
echo "3. Add your Hugging Face token (get from: https://huggingface.co/settings/tokens)"
echo "4. Start typing in Gmail/LinkedIn to see the magic!"