// TextCraft Pro Development Server
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 3000;
const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml'
};

const server = http.createServer((req, res) => {
  console.log(`${req.method} ${req.url}`);
  
  // Serve extension files
  let filePath = '.' + req.url;
  if (filePath === './') {
    filePath = './test.html';
  }
  
  const extname = path.extname(filePath);
  let contentType = MIME_TYPES[extname] || 'application/octet-stream';
  
  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code === 'ENOENT') {
        // File not found
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end('<h1>404 Not Found</h1><p>TextCraft Pro test server</p>');
      } else {
        // Server error
        res.writeHead(500);
        res.end('Server Error: ' + error.code);
      }
    } else {
      // Success
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(PORT, () => {
  console.log(`🚀 TextCraft Pro development server running at:`);
  console.log(`   http://localhost:${PORT}`);
  console.log(`   http://localhost:${PORT}/test.html`);
  console.log(`\n📦 Extension files are ready to load in Chrome:`);
  console.log(`   1. Open chrome://extensions/`);
  console.log(`   2. Enable "Developer mode"`);
  console.log(`   3. Click "Load unpacked"`);
  console.log(`   4. Select this directory: ${process.cwd()}`);
  console.log(`\n🔄 Server will automatically serve your files`);
});
