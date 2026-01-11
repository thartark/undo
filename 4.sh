#!/bin/bash
# 03_add_analytics.sh
echo "Adding Analytics & Stats module..."

mkdir -p TextCraftPro/modules/analytics

cat > TextCraftPro/modules/analytics/analytics.js << 'EOF'
// Analytics Module
class TextAnalytics {
  constructor() {
    this.readingSpeed = 200; // words per minute
  }
  
  getStats(text) {
    const stats = {
      characters: text.length,
      charactersNoSpaces: text.replace(/\s/g, '').length,
      words: this.countWords(text),
      sentences: this.countSentences(text),
      paragraphs: this.countParagraphs(text),
      readingTime: this.calculateReadingTime(text),
      readability: this.calculateReadability(text),
      wordFrequency: this.getWordFrequency(text)
    };
    
    return stats;
  }
  
  countWords(text) {
    return text.trim() ? text.trim().split(/\s+/).length : 0;
  }
  
  countSentences(text) {
    return (text.match(/[.!?]+/g) || []).length || 1;
  }
  
  countParagraphs(text) {
    return text.trim() ? text.split(/\n\s*\n/).length : 0;
  }
  
  calculateReadingTime(text) {
    const words = this.countWords(text);
    return Math.ceil(words / this.readingSpeed);
  }
  
  calculateReadability(text) {
    // Simple Flesch-Kincaid approximation
    const words = this.countWords(text);
    const sentences = this.countSentences(text);
    const syllables = this.estimateSyllables(text);
    
    if (words === 0 || sentences === 0) return 100;
    
    const score = 206.835 - 1.015 * (words / sentences) - 84.6 * (syllables / words);
    return Math.max(0, Math.min(100, score));
  }
  
  estimateSyllables(text) {
    // Very basic syllable estimation
    return text.toLowerCase()
      .replace(/[^a-z]/g, '')
      .split('')
      .filter(c => 'aeiouy'.includes(c)).length || 1;
  }
  
  getWordFrequency(text) {
    const words = text.toLowerCase()
      .replace(/[^\w\s]/g, '')
      .split(/\s+/)
      .filter(w => w.length > 2);
    
    const frequency = {};
    words.forEach(word => {
      frequency[word] = (frequency[word] || 0) + 1;
    });
    
    // Sort by frequency
    return Object.entries(frequency)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([word, count]) => ({word, count}));
  }
  
  getKeywordDensity(text) {
    const words = text.toLowerCase()
      .replace(/[^\w\s]/g, '')
      .split(/\s+/)
      .filter(w => w.length > 3);
    
    const total = words.length;
    const frequency = {};
    
    words.forEach(word => {
      frequency[word] = (frequency[word] || 0) + 1;
    });
    
    return Object.entries(frequency)
      .map(([word, count]) => ({
        word,
        count,
        density: ((count / total) * 100).toFixed(2) + '%'
      }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);
  }
  
  detectPassiveVoice(text) {
    // Basic passive voice detection
    const passivePatterns = [
      /\b(is|are|was|were|be|been|being)\s+\w+ed\b/gi,
      /\b(get|got|gets|getting)\s+\w+ed\b/gi
    ];
    
    let passiveCount = 0;
    passivePatterns.forEach(pattern => {
      const matches = text.match(pattern);
      if (matches) passiveCount += matches.length;
    });
    
    const totalSentences = this.countSentences(text);
    const percentage = totalSentences > 0 ? (passiveCount / totalSentences) * 100 : 0;
    
    return {
      count: passiveCount,
      percentage: percentage.toFixed(1),
      sentences: totalSentences
    };
  }
}

if (typeof module !== 'undefined') {
  module.exports = TextAnalytics;
} else {
  window.TextAnalytics = TextAnalytics;
}
EOF

cat > TextCraftPro/modules/analytics/popup_addition.html << 'EOF'
<div class="feature-section">
  <h2>📊 Detailed Analytics</h2>
  <div class="stats-grid">
    <div class="stat-card">
      <div class="stat-label">Reading Time</div>
      <div id="readingTime" class="stat-value-large">0 min</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Readability</div>
      <div id="readabilityScore" class="stat-value-large">0%</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Sentences</div>
      <div id="sentenceCount" class="stat-value">0</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">Paragraphs</div>
      <div id="paragraphCount" class="stat-value">0</div>
    </div>
  </div>
  
  <div class="advanced-stats" style="margin-top: 15px;">
    <h3 style="font-size: 14px; margin-bottom: 8px;">Top Keywords</h3>
    <div id="keywordList" class="keyword-list">
      <!-- Keywords will appear here -->
    </div>
    
    <button id="showMoreStats" class="btn" style="width: 100%; margin-top: 10px;">
      Show More Analytics
    </button>
    
    <div id="moreStats" style="display: none; margin-top: 10px;">
      <div class="stat-row">
        <span>Passive Voice:</span>
        <span id="passiveVoice">0%</span>
      </div>
      <div class="stat-row">
        <span>Avg. Sentence Length:</span>
        <span id="avgSentenceLength">0</span>
      </div>
      <div class="stat-row">
        <span>Unique Words:</span>
        <span id="uniqueWords">0</span>
      </div>
    </div>
  </div>
</div>

<style>
.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 10px;
  margin-bottom: 10px;
}

.stat-card {
  background: rgba(255, 255, 255, 0.1);
  padding: 10px;
  border-radius: 8px;
  text-align: center;
}

.stat-value-large {
  font-size: 20px;
  font-weight: bold;
  color: #4CAF50;
}

.keyword-list {
  display: flex;
  flex-wrap: wrap;
  gap: 5px;
}

.keyword-item {
  background: rgba(76, 175, 80, 0.2);
  padding: 4px 8px;
  border-radius: 12px;
  font-size: 11px;
}

.stat-row {
  display: flex;
  justify-content: space-between;
  padding: 5px 0;
  font-size: 12px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}
</style>
EOF

echo "✅ Analytics module created!"