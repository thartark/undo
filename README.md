# Undo - Safer Email Assistant

Chrome extension for AI-powered email safety checking in Gmail and LinkedIn.

## Installation
1. Open `chrome://extensions/`
2. Enable "Developer mode"
3. Click "Load unpacked"
4. Select this folder

## Setup
1. Get free token from https://huggingface.co/settings/tokens
2. Click Undo extension icon
3. Paste token (starts with `hf_`)
4. Click "Save Token"

## Usage
- Open Gmail or LinkedIn
- Start typing a message
- After 30+ characters, safety analysis appears
- Click "Use This Version" to apply safer alternative

## Files
- `manifest.json` - Extension configuration
- `content.js` - Main logic for Gmail/LinkedIn
- `popup.html/js` - Settings popup
- `content.css` - Styling
- `background.js` - Background service worker
- `icons/` - Extension icons
