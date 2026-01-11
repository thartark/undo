// server.js — full minimal Undo server with Hugging Face

const express = require("express");
const { HfInference } = require("@huggingface/inference");

// ===== Replace the string below with your actual Hugging Face token =====
const hf = new HfInference("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");

const app = express();
const PORT = 3000;

// allow JSON input
app.use(express.json());

// serve the homepage
app.get("/", (req, res) => {
  res.sendFile(__dirname + "/index.html");
});

// risk scan route
app.post("/scan", async (req, res) => {
  const { message } = req.body;
  if (!message) return res.json({ riskScore: 0, warning: "No message" });

  try {
    // Call Hugging Face text classification model
    const result = await hf.textClassification({
      model: "joeddav/distilbert-base-uncased-go-emotions-student",
      inputs: message,
    });

    // Determine "risk" from model output
    const highRiskEmotions = ["anger", "disgust", "fear"];
    let risk = 1;
    let warning = "Low risk message";

    result.forEach((r) => {
      if (highRiskEmotions.includes(r.label.toLowerCase()) && r.score > 0.3) {
        risk = 7;
        warning = `This message may cause tension (${r.label} detected)`;
      }
    });

    res.json({ riskScore: risk, warning });
  } catch (err) {
    console.error("Hugging Face API error:", err);
    res.status(500).json({ riskScore: 0, warning: "Error analyzing message" });
  }
});

app.listen(PORT, () => {
  console.log("Server running on http://localhost:" + PORT);
});

app.post('/rewrite', async (req, res) => {
  const { text } = req.body;

  if (!text) {
    return res.status(400).json({ error: 'No text provided' });
  }

  res.json({
    rewrite: "Here's a calmer version: " + text.replace(/!/g, ".")
  });
});
