const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage (replace with MongoDB for production)
let messages = [];
let stats = {
    totalMessages: 0,
    highRiskCount: 0,
    suggestionsUsed: 0
};

// API Routes
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        messagesCount: messages.length
    });
});

// Store a message
app.post('/api/messages', (req, res) => {
    try {
        const message = {
            id: Date.now().toString(),
            original: req.body.original?.substring(0, 500) || '',
            alternative: req.body.alternative || '',
            riskScore: req.body.riskScore || 0,
            riskLevel: req.body.riskLevel || 'low',
            timestamp: new Date().toISOString(),
            url: req.body.url || ''
        };
        
        messages.push(message);
        messages = messages.slice(-1000); // Keep only last 1000 messages
        
        // Update stats
        stats.totalMessages++;
        if (message.riskLevel === 'high') {
            stats.highRiskCount++;
        }
        
        console.log(`Stored message #${stats.totalMessages}`);
        res.status(201).json({ 
            success: true, 
            id: message.id,
            message: 'Message stored successfully'
        });
    } catch (error) {
        console.error('Error storing message:', error);
        res.status(500).json({ 
            error: 'Failed to store message',
            details: error.message 
        });
    }
});

// Get all messages
app.get('/api/messages', (req, res) => {
    const limit = parseInt(req.query.limit) || 50;
    res.json(messages.slice(-limit).reverse());
});

// Get statistics
app.get('/api/stats', (req, res) => {
    const highRiskPercentage = stats.totalMessages > 0 
        ? ((stats.highRiskCount / stats.totalMessages) * 100).toFixed(1)
        : '0.0';
    
    res.json({
        totalMessages: stats.totalMessages,
        highRiskCount: stats.highRiskCount,
        highRiskPercentage: highRiskPercentage,
        dailyAverage: calculateDailyAverage(),
        lastUpdated: new Date().toISOString()
    });
});

// Relationship graph data
app.get('/api/relationships', (req, res) => {
    // Extract domains from URLs
    const domains = {};
    messages.forEach(msg => {
        try {
            if (msg.url) {
                const url = new URL(msg.url);
                const domain = url.hostname.replace('www.', '');
                domains[domain] = (domains[domain] || 0) + 1;
            }
        } catch (e) {
            // Skip invalid URLs
        }
    });
    
    // Create nodes for D3.js graph
    const nodes = Object.keys(domains).map(domain => ({
        id: domain,
        group: 1,
        value: domains[domain],
        label: domain
    }));
    
    // Create links (simplified for demo)
    const links = [];
    if (nodes.length > 1) {
        links.push({
            source: nodes[0].id,
            target: nodes[nodes.length > 1 ? 1 : 0].id,
            value: 1
        });
    }
    
    res.json({ 
        nodes: nodes.slice(0, 10), // Limit to 10 nodes for demo
        links: links 
    });
});

// Helper function to calculate daily average
function calculateDailyAverage() {
    if (messages.length < 2) return '0.0';
    
    const firstDate = new Date(messages[0].timestamp);
    const lastDate = new Date(messages[messages.length - 1].timestamp);
    const days = Math.max(1, (lastDate - firstDate) / (1000 * 60 * 60 * 24));
    
    return (messages.length / days).toFixed(1);
}

// Dashboard HTML
app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Undo Dashboard</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    padding: 20px;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 20px;
                    padding: 40px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.1);
                }
                header {
                    text-align: center;
                    margin-bottom: 40px;
                }
                h1 {
                    color: #333;
                    font-size: 2.5em;
                    margin-bottom: 10px;
                }
                .subtitle {
                    color: #666;
                    font-size: 1.2em;
                }
                .stats-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                    gap: 20px;
                    margin-bottom: 40px;
                }
                .stat-card {
                    background: #f8f9fa;
                    padding: 25px;
                    border-radius: 15px;
                    text-align: center;
                    transition: transform 0.3s;
                }
                .stat-card:hover {
                    transform: translateY(-5px);
                }
                .stat-value {
                    font-size: 2.5em;
                    font-weight: bold;
                    color: #1a73e8;
                    margin-bottom: 10px;
                }
                .stat-label {
                    color: #666;
                    font-size: 0.9em;
                }
                .message-list {
                    background: #f8f9fa;
                    border-radius: 15px;
                    padding: 20px;
                    margin-top: 20px;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                }
                th, td {
                    padding: 15px;
                    text-align: left;
                    border-bottom: 1px solid #e0e0e0;
                }
                th {
                    background: #e8f0fe;
                    color: #1a73e8;
                    font-weight: 600;
                }
                .risk-high { color: #dc3545; font-weight: bold; }
                .risk-medium { color: #ffc107; font-weight: bold; }
                .risk-low { color: #28a745; font-weight: bold; }
                .refresh-btn {
                    background: #1a73e8;
                    color: white;
                    border: none;
                    padding: 12px 24px;
                    border-radius: 8px;
                    cursor: pointer;
                    font-size: 1em;
                    margin: 20px 0;
                    transition: background 0.3s;
                }
                .refresh-btn:hover {
                    background: #0d62d9;
                }
                footer {
                    text-align: center;
                    margin-top: 40px;
                    color: #999;
                    font-size: 0.9em;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <header>
                    <h1>📊 Undo Analytics Dashboard</h1>
                    <p class="subtitle">Real-time email safety statistics and message history</p>
                </header>
                
                <div class="stats-grid" id="statsGrid">
                    <!-- Stats will be loaded here -->
                </div>
                
                <button class="refresh-btn" onclick="loadData()">🔄 Refresh Data</button>
                
                <div class="message-list">
                    <h2 style="margin-bottom: 20px;">Recent Messages</h2>
                    <table>
                        <thead>
                            <tr>
                                <th>Time</th>
                                <th>Risk</th>
                                <th>Score</th>
                                <th>Domain</th>
                                <th>Preview</th>
                            </tr>
                        </thead>
                        <tbody id="messagesBody">
                            <tr><td colspan="5" style="text-align: center;">Loading messages...</td></tr>
                        </tbody>
                    </table>
                </div>
                
                <footer>
                    <p>Undo Chrome Extension v1.0.0 • Server running on port ${PORT}</p>
                    <p>API available at: /api/health, /api/messages, /api/stats, /api/relationships</p>
                </footer>
            </div>
            
            <script>
                async function loadData() {
                    try {
                        // Load stats
                        const statsRes = await fetch('/api/stats');
                        const stats = await statsRes.json();
                        
                        document.getElementById('statsGrid').innerHTML = \`
                            <div class="stat-card">
                                <div class="stat-value">\${stats.totalMessages}</div>
                                <div class="stat-label">Total Messages</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-value">\${stats.highRiskPercentage}%</div>
                                <div class="stat-label">High Risk Rate</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-value">\${stats.highRiskCount}</div>
                                <div class="stat-label">High Risk Messages</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-value">\${stats.dailyAverage}</div>
                                <div class="stat-label">Avg per Day</div>
                            </div>
                        \`;
                        
                        // Load messages
                        const messagesRes = await fetch('/api/messages?limit=10');
                        const messages = await messagesRes.json();
                        
                        const tbody = document.getElementById('messagesBody');
                        if (messages.length === 0) {
                            tbody.innerHTML = '<tr><td colspan="5" style="text-align: center;">No messages yet</td></tr>';
                        } else {
                            tbody.innerHTML = messages.map(msg => \`
                                <tr>
                                    <td>\${new Date(msg.timestamp).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</td>
                                    <td class="risk-\${msg.riskLevel}">\${msg.riskLevel.toUpperCase()}</td>
                                    <td>\${msg.riskScore}</td>
                                    <td>\${extractDomain(msg.url)}</td>
                                    <td title="\${msg.original}">\${msg.original.substring(0, 40)}...</td>
                                </tr>
                            \`).join('');
                        }
                        
                    } catch (error) {
                        console.error('Error loading data:', error);
                        document.getElementById('statsGrid').innerHTML = \`
                            <div class="stat-card" style="grid-column: 1 / -1;">
                                <div class="stat-value">⚠️</div>
                                <div class="stat-label">Error loading data. Check server connection.</div>
                            </div>
                        \`;
                    }
                }
                
                function extractDomain(url) {
                    if (!url) return 'Unknown';
                    try {
                        return new URL(url).hostname;
                    } catch (e) {
                        return url.length > 20 ? url.substring(0, 20) + '...' : url;
                    }
                }
                
                // Load data on page load
                loadData();
                
                // Auto-refresh every 30 seconds
                setInterval(loadData, 30000);
            </script>
        </body>
        </html>
    `);
});

// Start server
app.listen(PORT, () => {
    console.log(\`
    ╔══════════════════════════════════════════╗
    ║          Undo Server Started!            ║
    ╚══════════════════════════════════════════╝
    🌐 Dashboard: http://localhost:\${PORT}
    📡 API Health: http://localhost:\${PORT}/api/health
    📊 API Stats: http://localhost:\${PORT}/api/stats
    💾 API Messages: http://localhost:\${PORT}/api/messages
    🕸️ API Relationships: http://localhost:\${PORT}/api/relationships
    
    Server running on port \${PORT}
    Press Ctrl+C to stop
    \`);
});
