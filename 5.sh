#!/bin/bash
# 00_master_install.sh
echo "📦 TextCraft Pro - Master Installation Script"
echo "============================================="

# Check for required tools
if ! command -v zip &> /dev/null; then
    echo "Error: 'zip' command is required. Install it first."
    exit 1
fi

# Create build directory
BUILD_DIR="TextCraftPro/builds/complete"
mkdir -p $BUILD_DIR

echo ""
echo "Select installation mode:"
echo "1. Basic (Core features only)"
echo "2. Standard (Core + Quick Actions + Analytics)"
echo "3. Professional (All modules)"
echo "4. Custom (Select modules)"
echo ""
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        echo "Installing Basic version..."
        ./01_install_basic.sh
        cp -r TextCraftPro/core/* $BUILD_DIR/
        ;;
    2)
        echo "Installing Standard version..."
        ./01_install_basic.sh
        ./02_add_quick_actions.sh
        ./03_add_analytics.sh
        
        # Merge files
        cp -r TextCraftPro/core/* $BUILD_DIR/
        
        # Add module CSS
        cat TextCraftPro/modules/quick_actions/styles.css >> $BUILD_DIR/popup.css
        
        # Add module HTML
        sed -i '/<\/body>/i \ \ \ \ <!-- Quick Actions Module -->' $BUILD_DIR/popup.html
        sed -i '/<!-- Quick Actions Module -->/r TextCraftPro/modules/quick_actions/popup_addition.html' $BUILD_DIR/popup.html
        
        sed -i '/<\/body>/i \ \ \ \ <!-- Analytics Module -->' $BUILD_DIR/popup.html
        sed -i '/<!-- Analytics Module -->/r TextCraftPro/modules/analytics/popup_addition.html' $BUILD_DIR/popup.html
        
        # Update manifest
        jq '.name = "TextCraft Pro - Standard" | .description = "Enhanced text editor with analytics"' TextCraftPro/core/manifest.json > $BUILD_DIR/manifest.json
        ;;
    3)
        echo "Installing Professional version..."
        # This would run all module scripts
        echo "Professional version requires all 18 module scripts."
        echo "Creating placeholder for now..."
        ;;
    4)
        echo "Custom installation not implemented yet."
        ;;
    *)
        echo "Invalid choice. Installing Basic version."
        ./01_install_basic.sh
        ;;
esac

# Create ZIP file
echo ""
echo "Creating distribution package..."
cd $BUILD_DIR
zip -r ../../TextCraftPro.zip *
cd ../..

echo ""
echo "✅ Installation complete!"
echo ""
echo "📁 Files are in: $BUILD_DIR"
echo "📦 ZIP package: TextCraftPro/TextCraftPro.zip"
echo ""
echo "To install in Chrome:"
echo "1. Open chrome://extensions/"
echo "2. Enable 'Developer mode'"
echo "3. Click 'Load unpacked'"
echo "4. Select the '$BUILD_DIR' directory"
echo ""
echo "To update: Run this script again with new options"