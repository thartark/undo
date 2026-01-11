#!/bin/bash

mkdir -p chrome-extension

cat > chrome-extension/manifest.json << 'EOF'
{
  "manifest_version": 3,
  "name": "Undo",
  "version": "0.1",
  "description": "Warns you before sending risky messages.",
  "permissions": ["activeTab", "scripting"],
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"]
    }
  ]
}
EOF

cat > chrome-extension/content.js << 'EOF'
console.log("Undo loaded");
EOF

echo "✅ Chrome extension scaffold created"
