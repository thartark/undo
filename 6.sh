#!/bin/bash

# ===== 1️⃣ Upgrade UI with safer messages =====
mkdir -p public

cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>Undo – Message Risk Scanner</title>
  <style>
    body { font-family: system-ui; padding: 40px; max-width: 600px; }
    textarea { width: 100%; height: 150px; font-size: 16px; }
    button { margin-top: 10px; padding: 10px 16px; font-size: 16px; }
    .result { margin-top: 20px; font-size: 18px; }
    .low { color: green; }
    .medium { color: orange; }
    .high { color: red; font-weight: bold; }
    .rewrite { margin-top: 10px; font-style: italic; color: blue; }
  </style>
</head>
<body>

<h1>Undo</h1>
<p>Scan a message before you regret sending it.</p>

<textarea id="message" placeholder="Paste or write your message here..."></textarea>
<br />
<button onclick="scan()">Scan Risk</button>

<div id="result" class="result"></div>
<div id="rewrite" class="rewrite"></div>

<script>
async function scan() {
  const text = document.getElementById('message').value;

  // call /scan
  const scanRes = await fetch('/scan', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: text })
  });
  const data = await scanRes.json();

  // set risk color
  const result = document.getElementById('result');
  let cls = 'low';
  if (data.riskScore > 5) cls = 'high';
  else if (data.riskScore > 3) cls = 'medium';
  result.className = 'result ' + cls;
  result.innerHTML = `Risk Score: ${data.riskScore}<br/>${data.warning}`;

  // call /rewrite if high risk
  const rewriteDiv = document.getElementById('rewrite');
  if (data.riskScore > 3) {
    const rewriteRes = await fetch('/rewrite', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text })
    });
    const rewriteData = await rewriteRes.json();
    rewriteDiv.innerHTML = "Safer alternative: " + rewriteData.rewrite;
  } else {
    rewriteDiv.innerHTML = "";
  }
}
</script>

</body>
</html>
EOF

echo "✅ Public UI upgraded with safer message display"

# ===== 2️⃣ Add basic Chrome extension scaffold =====
mkdir -p chrome-extension

cat > chrome-extension/manifest.json << 'EOF'
{
  "manifest_version": 3,
  "name": "Undo",
  "version": "0.2",
  "description": "Warns you before sending risky messages.",
  "permissions": ["activeTab", "scripting"],
  "content_scripts": [
    {
      "matches": ["https://mail.google.com/*","https://www.linkedin.com/*"],
      "js": ["content.js"]
    }
  ]
}
EOF

cat > chrome-extension/content.js << 'EOF'
// basic content script: detects text areas
console.log("Undo extension active");

// observe text inputs
const observer = new MutationObserver(() => {
  document.querySelectorAll('textarea, input[type=text]').forEach(input => {
    if (!input.dataset.undoAttached) {
      input.dataset.undoAttached = "true";
      input.addEventListener("input", async () => {
        const text = input.value;
        try {
          const res = await fetch("http://localhost:3000/scan", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ message: text })
          });
          const data = await res.json();
          input.style.borderColor = data.riskScore > 3 ? "red" : "green";
        } catch (err) { console.log("Undo API error", err); }
      });
    }
  });
});
observer.observe(document.body, { childList: true, subtree: true });
EOF

echo "✅ Chrome extension scaffold updated with Gmail/LinkedIn injection"

# ===== 3️⃣ Test script for API =====
cat > scripts/test-undo.sh << 'EOF'
#!/bin/bash
echo "Testing /scan endpoint..."
curl -s -X POST http://localhost:3000/scan \
-H "Content-Type: application/json" \
-d '{"message":"I can’t believe you did that!"}'
echo ""
echo "Testing /rewrite endpoint..."
curl -s -X POST http://localhost:3000/rewrite \
-H "Content-Type: application/json" \
-d '{"text":"I can’t believe you did that!"}'
EOF

chmod +x scripts/test-undo.sh
echo "✅ Test script created: scripts/test-undo.sh"

echo "🎉 Full upgrade complete! Run your server: node server.js"
echo "Then open public/index.html or load chrome-extension folder into Chrome"
