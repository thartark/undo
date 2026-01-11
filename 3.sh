#!/bin/bash

cat >> server.js << 'EOF'

app.post('/rewrite', async (req, res) => {
  const { text } = req.body;

  if (!text) {
    return res.status(400).json({ error: 'No text provided' });
  }

  res.json({
    rewrite: "Here's a calmer version: " + text.replace(/!/g, ".")
  });
});
EOF

echo "✅ Rewrite endpoint added"
