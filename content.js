cd ~/code/undo

# Backup current file
cp content.js content.js.backup

# Create fixed version with working API call
cat > content.js << 'EOF'
// Undo Email Safety Assistant - FIXED API VERSION
console.log('[Undo] Extension loading...');

if (!window.undoLoaded) {
    window.undoLoaded = true;
    
    class EmailSafetyAssistant {
        constructor() {
            console.log('[Undo] Creating assistant');
            this.safetyPopup = null;
            this.currentMessage = '';
            this.isProcessing = false;
            this.hfToken = null;
            this.gmailTimeout = null;
            this.linkedinTimeout = null;
            
            this.loadToken();
            this.setupObservers();
            
            // Listen for token updates
            chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
                if (request.type === 'TOKEN_UPDATED') {
                    console.log('[Undo] Token updated via message');
                    this.hfToken = request.token;
                    this.showMessage('✅ Token updated! AI enabled.', 'success');
                }
                return true;
            });
        }
        
        async loadToken() {
            return new Promise((resolve) => {
                chrome.storage.local.get(['undoHFToken'], (result) => {
                    this.hfToken = result.undoHFToken;
                    console.log('[Undo] Token loaded:', this.hfToken ? 'Yes' : 'No');
                    if (this.hfToken) {
                        console.log('[Undo] Token starts with:', this.hfToken.substring(0, 10) + '...');
                    }
                    resolve();
                });
            });
        }
        
        setupObservers() {
            if (window.location.hostname.includes('mail.google.com')) {
                this.observeGmail();
            }
            if (window.location.hostname.includes('linkedin.com')) {
                this.observeLinkedIn();
            }
        }
        
        observeGmail() {
            const observer = new MutationObserver((mutations) => {
                const composeBox = document.querySelector('[role="textbox"][aria-label*="Message"], [role="textbox"][aria-label*="Compose"]');
                if (composeBox && composeBox.textContent.trim().length > 30) {
                    clearTimeout(this.gmailTimeout);
                    this.gmailTimeout = setTimeout(() => {
                        this.analyzeMessage(composeBox.textContent, composeBox);
                    }, 1500);
                }
            });
            observer.observe(document.body, { childList: true, subtree: true, characterData: true });
        }
        
        observeLinkedIn() {
            const observer = new MutationObserver((mutations) => {
                const messageBox = document.querySelector('.msg-form__contenteditable');
                if (messageBox && messageBox.textContent.trim().length > 30) {
                    clearTimeout(this.linkedinTimeout);
                    this.linkedinTimeout = setTimeout(() => {
                        this.analyzeMessage(messageBox.textContent, messageBox);
                    }, 1500);
                }
            });
            observer.observe(document.body, { childList: true, subtree: true });
        }
        
        async analyzeMessage(text, targetElement) {
            if (this.isProcessing || !text.trim()) return;
            
            console.log('[Undo] Analyzing message, token present:', !!this.hfToken);
            console.log('[Undo] Message preview:', text.substring(0, 50) + '...');
            
            if (!this.hfToken) {
                this.showNoTokenMessage(targetElement);
                return;
            }
            
            this.isProcessing = true;
            this.currentMessage = text;
            
            const loadingEl = this.showLoading(targetElement);
            
            try {
                // Try Hugging Face API with timeout
                const analysis = await Promise.race([
                    this.tryHuggingFaceAPI(text),
                    new Promise((_, reject) => 
                        setTimeout(() => reject(new Error('API timeout')), 5000)
                    )
                ]);
                
                loadingEl.remove();
                this.showSafetyPopup(analysis, targetElement);
                
            } catch (apiError) {
                console.log('[Undo] API failed, using local analysis:', apiError.message);
                loadingEl.remove();
                
                // Fallback to local analysis
                const localAnalysis = this.getLocalAnalysis(text);
                this.showSafetyPopup(localAnalysis, targetElement);
                
            } finally {
                this.isProcessing = false;
            }
        }
        
        async tryHuggingFaceAPI(text) {
            console.log('[Undo] Calling Hugging Face API...');
            
            // Truncate to avoid token limits
            const truncatedText = text.length > 300 ? text.substring(0, 300) + '...' : text;
            
            // Use a simpler model that's more likely to work
            const response = await fetch(
                "https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.1",
                {
                    method: "POST",
                    headers: {
                        "Authorization": `Bearer ${this.hfToken}`,
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        inputs: `Rewrite this email to be more professional: "${truncatedText}"`,
                        parameters: {
                            max_new_tokens: 100,
                            temperature: 0.7
                        }
                    })
                }
            );
            
            console.log('[Undo] API response status:', response.status);
            
            if (!response.ok) {
                throw new Error(`API error: ${response.status}`);
            }
            
            const data = await response.json();
            console.log('[Undo] API response:', data);
            
            // Extract generated text
            const generatedText = data[0]?.generated_text || '';
            const saferAlternative = generatedText.replace(/^.*?Rewrite this email to be more professional:\s*/i, '') || truncatedText;
            
            // Calculate risk score
            const riskScore = this.calculateRiskScore(truncatedText);
            const riskLevel = riskScore > 70 ? 'high' : riskScore > 40 ? 'medium' : 'low';
            
            return {
                riskScore: riskScore,
                riskLevel: riskLevel,
                issues: this.getIssues(truncatedText),
                saferAlternative: saferAlternative.trim() || "Hi,\n\n" + truncatedText,
                explanation: "AI-powered rewrite"
            };
        }
        
        getLocalAnalysis(text) {
            const riskScore = this.calculateRiskScore(text);
            const riskLevel = riskScore > 70 ? 'high' : riskScore > 40 ? 'medium' : 'low';
            
            // Simple text improvements
            let safer = text;
            safer = safer.replace(/urgent/gi, 'important');
            safer = safer.replace(/asap/gi, 'when convenient');
            safer = safer.replace(/hate/gi, 'dislike');
            safer = safer.replace(/!!!+/g, '!');
            safer = safer.replace(/\?\?\?+/g, '?');
            safer = safer.replace(/([A-Z]{4,})/g, match => 
                match.charAt(0).toUpperCase() + match.slice(1).toLowerCase()
            );
            
            if (!safer.match(/^(hi|hello|dear|hey)/i)) {
                safer = "Hi,\n\n" + safer;
            }
            
            return {
                riskScore: riskScore,
                riskLevel: riskLevel,
                issues: this.getIssues(text),
                saferAlternative: safer,
                explanation: "Local safety improvements applied"
            };
        }
        
        calculateRiskScore(text) {
            let score = 0;
            const riskWords = [
                'urgent', 'asap', 'immediately', 'now', 'deadline',
                'hate', 'stupid', 'idiot', 'terrible', 'awful',
                'fire', 'terminate', 'sue', 'lawsuit', 'angry', 'mad'
            ];
            
            riskWords.forEach(word => {
                const regex = new RegExp(`\\b${word}\\b`, 'gi');
                const matches = text.match(regex);
                if (matches) score += matches.length * 10;
            });
            
            // Check for all caps
            const allCapsMatches = text.match(/[A-Z]{4,}/g);
            if (allCapsMatches) score += allCapsMatches.length * 15;
            
            // Check for excessive punctuation
            if (text.includes('!!!')) score += 20;
            if (text.includes('???')) score += 15;
            
            return Math.min(score, 100);
        }
        
        getIssues(text) {
            const issues = [];
            
            if (text.match(/[A-Z]{4,}/)) {
                issues.push("ALL CAPS can be perceived as shouting");
            }
            if (text.includes('!!!')) {
                issues.push("Multiple exclamation points may seem emotional");
            }
            if (text.toLowerCase().includes('urgent') || text.toLowerCase().includes('asap')) {
                issues.push("Urgent language can create unnecessary pressure");
            }
            if (text.toLowerCase().includes('hate') || text.toLowerCase().includes('stupid')) {
                issues.push("Negative language detected");
            }
            
            if (issues.length === 0) {
                issues.push("No major issues detected");
            }
            
            return issues.slice(0, 3);
        }
        
        showLoading(targetElement) {
            const loading = document.createElement('div');
            loading.innerHTML = `
                <div style="display:flex;align-items:center;gap:10px;">
                    <div style="width:20px;height:20px;border:2px solid #f3f3f3;border-top:2px solid #1a73e8;border-radius:50%;animation:spin 1s linear infinite;"></div>
                    <span>Analyzing with AI...</span>
                </div>
            `;
            
            Object.assign(loading.style, {
                position: 'absolute',
                background: 'white',
                padding: '12px 16px',
                borderRadius: '8px',
                boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                zIndex: '9999',
                fontSize: '14px',
                color: '#1a73e8',
                border: '1px solid #e0e0e0',
                fontFamily: 'Arial, sans-serif'
            });
            
            // Add spinner animation
            if (!document.querySelector('#undo-spinner-style')) {
                const style = document.createElement('style');
                style.id = 'undo-spinner-style';
                style.textContent = `
                    @keyframes spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                `;
                document.head.appendChild(style);
            }
            
            const rect = targetElement.getBoundingClientRect();
            loading.style.top = `${rect.top + window.scrollY - 45}px`;
            loading.style.left = `${rect.left + window.scrollX}px`;
            
            document.body.appendChild(loading);
            return loading;
        }
        
        showNoTokenMessage(targetElement) {
            const msg = document.createElement('div');
            msg.innerHTML = '🔑 <a href="#" style="color:#1a73e8;text-decoration:underline;font-weight:bold;">Add Hugging Face Token</a> to enable AI analysis';
            Object.assign(msg.style, {
                position: 'absolute',
                background: '#fff3cd',
                padding: '12px 16px',
                borderRadius: '8px',
                boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
                zIndex: '9999',
                fontSize: '14px',
                color: '#856404',
                border: '1px solid #ffeaa7',
                maxWidth: '320px',
                fontFamily: 'Arial, sans-serif'
            });
            
            const rect = targetElement.getBoundingClientRect();
            msg.style.top = `${rect.top + window.scrollY - 45}px`;
            msg.style.left = `${rect.left + window.scrollX}px`;
            
            msg.querySelector('a').addEventListener('click', (e) => {
                e.preventDefault();
                chrome.runtime.sendMessage({action: 'openPopup'});
            });
            
            document.body.appendChild(msg);
            setTimeout(() => {
                if (msg.parentNode) msg.parentNode.removeChild(msg);
            }, 5000);
        }
        
        showSafetyPopup(analysis, targetElement) {
            if (this.safetyPopup) this.safetyPopup.remove();
            
            this.safetyPopup = document.createElement('div');
            const riskColor = analysis.riskLevel === 'high' ? '#dc3545' : 
                             analysis.riskLevel === 'medium' ? '#ffc107' : '#28a745';
            
            this.safetyPopup.innerHTML = `
                <div style="background:#1a73e8;color:white;padding:15px 20px;border-radius:10px 10px 0 0;display:flex;justify-content:space-between;align-items:center;font-family:Arial,sans-serif;">
                    <h3 style="margin:0;font-size:16px;font-weight:600;">🔒 Undo Safety Check</h3>
                    <span style="cursor:pointer;font-size:24px;line-height:1;">×</span>
                </div>
                <div style="padding:20px;border-left:5px solid ${riskColor};font-family:Arial,sans-serif;">
                    <div style="display:flex;align-items:center;gap:15px;margin-bottom:15px;">
                        <span style="font-size:36px;font-weight:bold;color:#333;">${analysis.riskScore}</span>
                        <span style="font-size:13px;font-weight:600;padding:6px 14px;border-radius:15px;background:#f8f9fa;color:#333;text-transform:uppercase;">
                            ${analysis.riskLevel.toUpperCase()} RISK
                        </span>
                    </div>
                    <div style="font-size:14px;color:#333;">
                        <strong>⚠️ Potential Issues:</strong>
                        <ul style="margin:10px 0 0 20px;padding:0;color:#666;">
                            ${analysis.issues.map(issue => `<li style="margin-bottom:6px;">${issue}</li>`).join('')}
                        </ul>
                    </div>
                </div>
                <div style="padding:20px;background:#f8f9fa;border-top:1px solid #eee;font-family:Arial,sans-serif;">
                    <strong style="display:block;margin-bottom:10px;color:#333;">✨ Safer Alternative:</strong>
                    <div style="background:white;padding:15px;border-radius:8px;margin:10px 0;border:1px solid #ddd;font-size:14px;line-height:1.5;max-height:200px;overflow-y:auto;white-space:pre-wrap;">
                        ${analysis.saferAlternative}
                    </div>
                    <button style="background:#1a73e8;color:white;border:none;padding:12px 20px;border-radius:8px;cursor:pointer;font-size:14px;font-weight:600;width:100%;margin-top:10px;transition:background 0.2s;">
                        Use This Version
                    </button>
                </div>
                <div style="padding:12px 20px;background:#f1f3f4;border-top:1px solid #ddd;font-size:12px;color:#666;text-align:center;font-family:Arial,sans-serif;">
                    ${analysis.explanation}
                </div>
            `;
            
            Object.assign(this.safetyPopup.style, {
                position: 'fixed',
                background: 'white',
                borderRadius: '10px',
                boxShadow: '0 6px 25px rgba(0,0,0,0.2)',
                zIndex: '10000',
                width: '400px',
                maxWidth: 'calc(100vw - 40px)',
                animation: 'undoSlideIn 0.3s ease'
            });
            
            // Add animation
            if (!document.querySelector('#undo-animation')) {
                const style = document.createElement('style');
                style.id = 'undo-animation';
                style.textContent = `
                    @keyframes undoSlideIn {
                        from { opacity: 0; transform: translateY(-15px); }
                        to { opacity: 1; transform: translateY(0); }
                    }
                `;
                document.head.appendChild(style);
            }
            
            const rect = targetElement.getBoundingClientRect();
            this.safetyPopup.style.top = `${rect.bottom + window.scrollY + 15}px`;
            this.safetyPopup.style.left = `${Math.max(20, rect.left + window.scrollX)}px`;
            
            document.body.appendChild(this.safetyPopup);
            
            // Close button
            this.safetyPopup.querySelector('span').addEventListener('click', () => {
                this.safetyPopup.remove();
            });
            
            // Use alternative button
            this.safetyPopup.querySelector('button').addEventListener('click', () => {
                targetElement.textContent = analysis.saferAlternative;
                this.safetyPopup.remove();
                this.showMessage('✅ Safer alternative applied!', 'success');
            });
        }
        
        showMessage(text, type) {
            const msg = document.createElement('div');
            msg.textContent = text;
            Object.assign(msg.style, {
                position: 'fixed',
                top: '25px',
                right: '25px',
                background: type === 'success' ? '#4CAF50' : '#ff9800',
                color: 'white',
                padding: '15px 25px',
                borderRadius: '8px',
                zIndex: '100000',
                fontSize: '14px',
                fontWeight: '600',
                boxShadow: '0 5px 15px rgba(0,0,0,0.2)',
                fontFamily: 'Arial, sans-serif',
                animation: 'fadeInOut 3s ease'
            });
            
            // Add fade animation
            if (!document.querySelector('#undo-fade-animation')) {
                const style = document.createElement('style');
                style.id = 'undo-fade-animation';
                style.textContent = `
                    @keyframes fadeInOut {
                        0% { opacity: 0; transform: translateX(20px); }
                        10% { opacity: 1; transform: translateX(0); }
                        90% { opacity: 1; transform: translateX(0); }
                        100% { opacity: 0; transform: translateX(20px); }
                    }
                `;
                document.head.appendChild(style);
            }
            
            document.body.appendChild(msg);
            setTimeout(() => {
                if (msg.parentNode) msg.parentNode.removeChild(msg);
            }, 3000);
        }
    }
    
    // Initialize
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => {
            console.log('[Undo] DOM loaded, starting assistant');
            window.undoAssistant = new EmailSafetyAssistant();
        });
    } else {
        console.log('[Undo] DOM already loaded, starting assistant');
        window.undoAssistant = new EmailSafetyAssistant();
    }
}
EOF

echo "✅ Updated content.js with FIXED API handling"
echo ""
echo "🔄 Now refresh the extension:"
echo "1. Go to chrome://extensions/"
echo "2. Find 'Undo' extension"
echo "3. Click the 🔄 Refresh icon"
echo "4. Refresh Gmail page (Cmd+R)"
echo "5. Try typing again!"