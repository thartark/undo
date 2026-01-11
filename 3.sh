#!/bin/bash
# 02_add_quick_actions.sh
echo "Adding Quick Actions module..."

# Create module directory
mkdir -p TextCraftPro/modules/quick_actions

# Create module manifest
cat > TextCraftPro/modules/quick_actions/manifest.json << 'EOF'
{
  "name": "TextCraft Pro - Quick Actions",
  "version": "1.0.0",
  "description": "Quick text transformations and actions",
  "permissions": ["activeTab", "storage"]
}
EOF

# Create module CSS
cat > TextCraftPro/modules/quick_actions/styles.css << 'EOF'
.quick-actions-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  margin-bottom: 15px;
}

.quick-action-btn {
  padding: 8px;
  font-size: 11px;
  background: rgba(255, 255, 255, 0.15);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.quick-action-btn:hover {
  background: rgba(255, 255, 255, 0.25);
  transform: translateY(-1px);
}

.emoji-picker {
  max-height: 200px;
  overflow-y: auto;
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 5px;
  padding: 10px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 5px;
}

.emoji-item {
  padding: 5px;
  text-align: center;
  cursor: pointer;
  border-radius: 3px;
}

.emoji-item:hover {
  background: rgba(255, 255, 255, 0.2);
}
EOF

# Create module JavaScript
cat > TextCraftPro/modules/quick_actions/quick_actions.js << 'EOF'
// Quick Actions Module
class QuickActions {
  constructor() {
    this.actions = {
      uppercase: text => text.toUpperCase(),
      lowercase: text => text.toLowerCase(),
      titlecase: text => text.replace(/\b\w/g, c => c.toUpperCase()),
      sentencecase: text => text.charAt(0).toUpperCase() + text.slice(1).toLowerCase(),
      sponge: text => text.split('').map((c, i) => i % 2 ? c.toUpperCase() : c.toLowerCase()).join(''),
      reverse: text => text.split('').reverse().join(''),
      trim: text => text.trim(),
      removeSpaces: text => text.replace(/\s+/g, ''),
      removeDuplicates: text => [...new Set(text.split('\n'))].join('\n'),
      sortLines: text => text.split('\n').sort().join('\n'),
      sortLinesLength: text => text.split('\n').sort((a, b) => a.length - b.length).join('\n'),
      addNumbers: text => text.split('\n').map((line, i) => `${i + 1}. ${line}`).join('\n'),
      removeNumbers: text => text.replace(/^\d+\.\s*/gm, '')
    };
    
    this.commonEmojis = ['😀', '😂', '🥰', '😎', '🤔', '🚀', '⭐', '💡', '📝', '🔧', '🎨', '📊', '💯', '✅', '❌', '⚠️', 'ℹ️', '✨', '🎯', '🔥'];
  }
  
  applyAction(actionName, text) {
    if (this.actions[actionName]) {
      return this.actions[actionName](text);
    }
    return text;
  }
  
  insertEmoji(emoji) {
    const element = this.getActiveElement();
    if (element) {
      const start = element.selectionStart;
      const end = element.selectionEnd;
      element.value = element.value.substring(0, start) + emoji + element.value.substring(end);
      element.selectionStart = element.selectionEnd = start + emoji.length;
      element.dispatchEvent(new Event('input', {bubbles: true}));
      return true;
    }
    return false;
  }
  
  getActiveElement() {
    const active = document.activeElement;
    if (active.tagName === 'TEXTAREA' || active.tagName === 'INPUT') {
      return active;
    }
    return document.querySelector('textarea, [contenteditable="true"]');
  }
}

// Export for use in content script
if (typeof module !== 'undefined') {
  module.exports = QuickActions;
} else {
  window.QuickActions = QuickActions;
}
EOF

# Create popup addition
cat > TextCraftPro/modules/quick_actions/popup_addition.html << 'EOF'
<div class="feature-section">
  <h2>⚡ Quick Actions</h2>
  <div class="quick-actions-grid">
    <button class="quick-action-btn" data-action="uppercase">UPPER</button>
    <button class="quick-action-btn" data-action="lowercase">lower</button>
    <button class="quick-action-btn" data-action="titlecase">Title</button>
    <button class="quick-action-btn" data-action="sentencecase">Sentence</button>
    <button class="quick-action-btn" data-action="sponge">sPoNgE</button>
    <button class="quick-action-btn" data-action="reverse">Reverse</button>
    <button class="quick-action-btn" data-action="trim">Trim</button>
    <button class="quick-action-btn" data-action="removeSpaces">No Spaces</button>
    <button class="quick-action-btn" data-action="removeDuplicates">No Dupes</button>
  </div>
  
  <div class="emoji-section" style="margin-top: 10px;">
    <button id="showEmojis" class="btn" style="width: 100%;">😀 Insert Emoji</button>
    <div id="emojiPicker" class="emoji-picker" style="display: none; margin-top: 10px;"></div>
  </div>
</div>
EOF

echo "✅ Quick Actions module created!"
echo ""
echo "To integrate this module:"
echo "1. Copy the CSS to your popup.css"
echo "2. Add the HTML to your popup.html"
echo "3. Include quick_actions.js in your content script"