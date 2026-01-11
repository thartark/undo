#!/bin/bash

echo "Setting up minimal Undo app..."

# init npm
npm init -y

# install express
npm install express

# create server.js
cat << 'EOF' > server.js
const express = require("express");
const app = express();
const PORT = 3000;

app.get("/", (req, res) => {
  res.send("Undo server is running");
});

app.listen(PORT, () => {
  console.log("Server running on http://localhost:" + PORT);
});
EOF

echo "Done."
echo "Next run: node server.js"

