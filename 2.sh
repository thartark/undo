#!/bin/bash

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
  </style>
</head>
<body>

<h1>Undo</h1>
<p>Scan a message before you regret sending it.</p>

<textarea id="message" placeholder="Paste or write your message here..."></textarea>
<br />
<button onclick="scan()">Scan Risk</button>

<div id="result" class="result"></div>

<script>
async function scan() {
  const text = document.getElementById('message').value;
  const res = await fetch('/scan', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text })
  });

  const data = await res.json();
  const result = document.getElementById('result');

  let cls = 'low';
  if (data.risk > 0.5) cls = 'high';
  else if (data.risk > 0.25) cls = 'medium';

  result.className = 'result ' + cls;
  result.innerHTML = `
    Risk Score: ${data.risk}<br/>
    ${data.warning}
  `;
}
</script>

</body>
</html>
EOF

echo "✅ UI upgraded"
