const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

let messages = [];
let stats = { totalMessages: 0, highRiskCount: 0 };

// Health check
app.get('/api/health', (req, res) => {
    res.json({ status: 'OK', messages: messages.length, timestamp: new Date().toISOString() });
});

// Store a message
app.post('/api/messages', (req, res) => {
    try {
        const msg = { id: Date.now(), ...req.body, timestamp: new Date().toISOString() };
        messages.push(msg);
        messages = messages.slice(-1000);
        stats.totalMessages++;
        if (msg.riskLevel === 'high') stats.highRiskCount++;
        res.status(201).json({ success: true, id: msg.id });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Get stats
app.get('/api/stats', (req, res) => {
    const highRiskPct = stats.totalMessages > 0 ? ((stats.highRiskCount / stats.totalMessages) * 100).toFixed(1) : '0.0';
    res.json({ ...stats, highRiskPercentage: highRiskPct });
});

// Simple dashboard
app.get('/', (req, res) => {
    res.send(`
        <html><head><title>Undo Dashboard</title><style>body{font-family:sans-serif;padding:2em}</style></head>
        <body><h1>Undo Dashboard</h1><p>Total Messages: <strong>${stats.totalMessages}</strong></p><p>High Risk: <strong>${stats.highRiskCount}</strong></p></body></html>
    `);
});

app.listen(PORT, () => console.log(\`🚀 Undo Server: http://localhost:\${PORT}\`));
