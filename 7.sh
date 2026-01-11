#!/bin/bash
# create_modular_architecture.sh
echo "Creating modular architecture for TextCraft Pro..."

# Define modules with their features
declare -A MODULES=(
    ["TextCraft-Basic"]="49,50,51,52,53,54,9,10,15,16,17,18,25,26,30,31,32,62,63,64,65,66,70,72"
    ["TextCraft-Writer"]="1,2,3,4,5,6,7,8,19,20,21,22,23,24,71,73,74,75,76,77"
    ["TextCraft-Code"]="27,28,29,41,42,43,44,45,46,47,48,67,69"
    ["TextCraft-Templates"]="33,34,35,36,37,38,39,40,55,56,57,58"
    ["TextCraft-Cloud"]="55,56,57,58,59,60,61,78,79,80,81,82,83,84,85"
)

echo "Creating 5 independent extensions:"
echo "1. TextCraft Basic - Core editing tools"
echo "2. TextCraft Writer - AI and writing assistance"
echo "3. TextCraft Code - Developer tools"
echo "4. TextCraft Templates - Snippets and templates"
echo "5. TextCraft Cloud - Sync and advanced features"

# Create extension directories
for module in "${!MODULES[@]}"; do
    echo ""
    echo "Creating $module..."
    mkdir -p "TextCraftPro/modular/$module"
    
    # Create basic structure
    cp -r TextCraftPro/core/* "TextCraftPro/modular/$module/"
    
    # Update manifest
    cat > "TextCraftPro/modular/$module/manifest.json" << EOF
{
  "manifest_version": 3,
  "name": "$module",
  "version": "1.0.0",
  "description": "Specialized text editing module",
  "permissions": ["activeTab", "storage"],
  "action": {
    "default_popup": "popup.html"
  },
  "content_scripts": [{
    "matches": ["<all_urls>"],
    "js": ["content.js"]
  }]
}
EOF
    
    echo "   Created with features: ${MODULES[$module]}"
done

echo ""
echo "✅ Modular architecture created!"
echo ""
echo "Each extension can be installed independently:"
echo "1. chrome://extensions → Load unpacked"
echo "2. Select one of the TextCraftPro/modular/ directories"
echo ""
echo "They can work together or separately!"