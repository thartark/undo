# Undo - Safer Email Assistant

A Chrome extension that checks emails in Gmail/LinkedIn for safety and suggests improvements.

## Quick Start

### 1. Install the Chrome Extension
1. Open Chrome and go to `chrome://extensions/`
2. Enable **"Developer mode"** (top-right toggle).
3. Click **"Load unpacked"**.
4. Select the **root folder of this project** (where `manifest.json` is).

### 2. Configure
1. Click the Undo extension icon (blue "U") in Chrome's toolbar.
2. Get a free token from [Hugging Face](https://huggingface.co/settings/tokens).
3. Paste the token (starts with `hf_`) and click **Save**.

### 3. Start the Local Server (Optional)
```bash
cd server
npm install
npm start
