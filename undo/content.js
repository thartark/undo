// Wrap everything in a check to prevent duplicate execution
if (!window.undoExtensionLoaded) {
    window.undoExtensionLoaded = true;
    
    class EmailSafetyAssistant {
        constructor() {
            this.safetyPopup = null;
            this.currentMessage = '';
            this.isProcessing = false;
            this.hfToken = null;
            this.serverUrl = 'http://localhost:3000';
            this.gmailTimeout = null;
            this.linkedinTimeout = null;
            
            console.log('Undo extension loaded');
            this.init();
        }

        async init() {
            // Load Hugging Face token from storage
            chrome.storage.local.get(['undoHFToken'], (result) => {
                this.hfToken = result.undoHFToken;
                if (!this.hfToken) {
                    console.log('No Hugging Face token found. Please add one in extension popup.');
                } else {
                    console.log('Hugging Face token loaded');
                }
            });

            this.setupObservers();
            this.injectStyles();
        }

        setupObservers() {
            if (window.location.hostname === 'mail.google.com') {
                this.observeGmail();
            }
            
            if (window.location.hostname === 'www.linkedin.com') {
                this.observeLinkedIn();
            }
        }

        observeGmail() {
            const observer = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                    const composeBox = document.querySelector('[role="textbox"][aria-label*="Message"], [role="textbox"][aria-label*="Compose"]');
                    if (composeBox && composeBox.textContent.trim().length > 30) {
                        // Debounce to avoid too many API calls
                        clearTimeout(this.gmailTimeout);
                        this.gmailTimeout = setTimeout(() => {
                            this.analyzeMessage(composeBox.textContent, composeBox);
                        }, 1000);
                    }
                });
            });

            observer.observe(document.body, {
                childList: true,
                subtree: true,
                attributes: true,
                characterData: true
            });
        }

        observeLinkedIn() {
            const observer = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                    const messageBox = document.querySelector('.msg-form__contenteditable');
                    if (messageBox && messageBox.textContent.trim().length > 30) {
                        clearTimeout(this.linkedinTimeout);
                        this.linkedinTimeout = setTimeout(() => {
                            this.analyzeMessage(messageBox.textContent, messageBox);
                        }, 1000);
                    }
                });
            });

            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
        }

        async analyzeMessage(text, targetElement) {
            if (this.isProcessing || !text.trim()) {
                return;
            }
            
            // If no token, show friendly message instead of error
            if (!this.hfToken) {
                this.showNoTokenMessage(targetElement);
                return;
            }
            
            this.isProcessing = true;
            this.currentMessage = text;
            
            this.showLoading(targetElement);
            
            try {
                const analysis = await this.getSafetyAnalysis(text);
                this.showSafetyPopup(analysis, targetElement);
                await this.storeMessageHistory(text, analysis);
            } catch (error) {
                console.error('Analysis error:', error);
                this.showError(targetElement, 'Analysis failed. Check token or try again.');
            } finally {
                this.isProcessing = false;
            }
        }

        showNoTokenMessage(targetElement) {
            const message = document.createElement('div');
            message.innerHTML = '🔑 <a href="#" style="color: #1a73e8; text-decoration: underline;">Add Hugging Face token</a> to enable AI analysis';
            message.style.cssText = `
                position: absolute;
                background: #fff3cd;
                padding: 8px 12px;
                border-radius: 4px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                z-index: 9999;
                font-size: 12px;
                color: #856404;
                border: 1px solid #ffeaa7;
                max-width: 300px;
            `;
            
            const rect = targetElement.getBoundingClientRect();
            message.style.top = `${rect.top + window.scrollY - 35}px`;
            message.style.left = `${rect.left + window.scrollX}px`;
            
            // Make link open extension popup
            message.querySelector('a').addEventListener('click', (e) => {
                e.preventDefault();
                chrome.runtime.sendMessage({ action: 'openPopup' });
            });
            
            document.body.appendChild(message);
            setTimeout(() => message.remove(), 5000);
        }

        async getSafetyAnalysis(text) {
            console.log('Analyzing message with Hugging Face...');
            
            // Truncate text to avoid token limits
            const truncatedText = text.length > 500 ? text.substring(0, 500) + '...' : text;
            
            try {
                // Using GPT-2 model (free, no waitlist)
                const response = await fetch(
                    "https://api-inference.huggingface.co/models/gpt2",
                    {
                        method: "POST",
                        headers: {
                            "Authorization": `Bearer ${this.hfToken}`,
                            "Content-Type": "application/json"
                        },
                        body: JSON.stringify({
                            inputs: `Analyze this email for safety and professionalism: "${truncatedText}"\n\nSafe alternative:`,
                            parameters: {
                                max_new_tokens: 100,
                                temperature: 0.7,
                                top_p: 0.9
                            }
                        })
                    }
                );

                if (!response.ok) {
                    throw new Error(`Hugging Face API error: ${response.status}`);
                }

                const data = await response.json();
                const generatedText = data[0]?.generated_text || '';
                
                // Extract the alternative (everything after "Safe alternative:")
                const alternativeMatch = generatedText.split('Safe alternative:')[1];
                
                return {
                    riskScore: this.calculateRiskScore(truncatedText),
                    riskLevel: this.determineRiskLevel(truncatedText),
                    issues: this.findIssues(truncatedText),
                    saferAlternative: alternativeMatch ? alternativeMatch.trim() : this.generateSaferAlternative(truncatedText),
                    explanation: "AI-generated safer version"
                };
                
            } catch (error) {
                console.log('Falling back to rule-based analysis');
                return this.getLocalAnalysis(truncatedText);
            }
        }

        getLocalAnalysis(text) {
            return {
                riskScore: this.calculateRiskScore(text),
                riskLevel: this.determineRiskLevel(text),
                issues: this.findIssues(text),
                saferAlternative: this.generateSaferAlternative(text),
                explanation: "Local safety analysis"
            };
        }

        calculateRiskScore(text) {
            let score = 0;
            const riskWords = [
                'urgent', 'immediately', 'asap', 'angry', 'mad', 'furious',
                'fire', 'terminate', 'sue', 'lawsuit', 'confidential',
                'password', 'ssn', 'credit card', '$$$', 'deadline',
                'mistake', 'wrong', 'failed', 'late', 'stupid', 'idiot'
            ];
            
            riskWords.forEach(word => {
                const regex = new RegExp(`\\b${word}\\b`, 'gi');
                if (regex.test(text)) score += 8;
            });
            
            // Check for all caps (yelling)
            const allCaps = text.match(/[A-Z]{4,}/g);
            if (allCaps) score += allCaps.length * 5;
            
            // Check for negative words
            const negativeWords = ['hate', 'worst', 'terrible', 'useless', 'ridiculous'];
            negativeWords.forEach(word => {
                const regex = new RegExp(`\\b${word}\\b`, 'gi');
                if (regex.test(text)) score += 12;
            });
            
            // Check for multiple punctuation
            if (text.includes('!!!') || text.includes('???')) score += 10;
            
            return Math.min(score, 100);
        }

        determineRiskLevel(text) {
            const score = this.calculateRiskScore(text);
            if (score > 70) return 'high';
            if (score > 40) return 'medium';
            return 'low';
        }

        findIssues(text) {
            const issues = [];
            
            // Check for shouting
            if ((text.match(/[A-Z]{4,}/g) || []).length > 0) {
                issues.push("ALL CAPS can be perceived as shouting");
            }
            
            // Check for excessive punctuation
            if (text.includes('!!!')) {
                issues.push("Multiple exclamation points may seem overly emotional");
            }
            if (text.includes('???')) {
                issues.push("Multiple question marks may seem impatient");
            }
            
            // Check for urgency language
            const urgentWords = ['urgent', 'asap', 'immediately', 'right now'];
            urgentWords.forEach(word => {
                if (text.toLowerCase().includes(word)) {
                    issues.push(`Urgent language ("${word}") can create pressure`);
                }
            });
            
            // Check for negative language
            const negativeWords = ['hate', 'stupid', 'idiot', 'terrible'];
            negativeWords.forEach(word => {
                if (text.toLowerCase().includes(word)) {
                    issues.push(`Negative word detected: "${word}"`);
                }
            });
            
            if (issues.length === 0) {
                issues.push("No major safety issues detected");
            }
            
            return issues.slice(0, 3);
        }

        generateSaferAlternative(text) {
            let safer = text;
            
            // Replace negative words
            const replacements = {
                'hate': 'prefer not to',
                'stupid': 'unwise',
                'idiot': 'person',
                'terrible': 'challenging',
                'fire': 'let go',
                'urgent': 'important',
                'asap': 'when you have a chance',
                'immediately': 'soon',
                'wrong': 'different',
                'failed': 'did not succeed',
                'deadline': 'timeline'
            };
            
            Object.keys(replacements).forEach(word => {
                const regex = new RegExp(`\\b${word}\\b`, 'gi');
                safer = safer.replace(regex, replacements[word]);
            });
            
            // Fix all caps
            safer = safer.replace(/([A-Z]{4,})/g, match => {
                return match.charAt(0).toUpperCase() + match.slice(1).toLowerCase();
            });
            
            // Reduce excessive punctuation
            safer = safer.replace(/!{3,}/g, '!');
            safer = safer.replace(/\?{3,}/g, '?');
            
            // Add polite opening if missing
            if (!safer.match(/^(hi|hello|dear|hey)/i)) {
                safer = "Hi,\n\n" + safer;
            }
            
            return safer;
        }

        showSafetyPopup(analysis, targetElement) {
            if (this.safetyPopup) this.safetyPopup.remove();

            this.safetyPopup = document.createElement('div');
            this.safetyPopup.className = 'undo-safety-popup';
            
            const riskColor = analysis.riskLevel === 'high' ? '#dc3545' : 
                             analysis.riskLevel === 'medium' ? '#ffc107' : '#28a745';
            
            this.safetyPopup.innerHTML = `
                <div class="undo-popup-header">
                    <h3>🔒 Undo Safety Check</h3>
                    <span class="undo-close">&times;</span>
                </div>
                <div class="undo-risk-indicator" style="border-left-color: ${riskColor}">
                    <div class="undo-risk-score">
                        <span class="undo-score">${analysis.riskScore}</span>
                        <span class="undo-risk-level">${analysis.riskLevel.toUpperCase()} RISK</span>
                    </div>
                    <div class="undo-issues">
                        <strong>⚠️ Potential Issues:</strong>
                        <ul>
                            ${analysis.issues.map(issue => `<li>${issue}</li>`).join('')}
                        </ul>
                    </div>
                </div>
                <div class="undo-alternative">
                    <strong>✨ Safer Alternative:</strong>
                    <div class="undo-safer-text">${analysis.saferAlternative}</div>
                    <button class="undo-use-alternative">Use This Version</button>
                </div>
                <div class="undo-explanation">
                    <small>${analysis.explanation}</small>
                </div>
                <div class="undo-footer">
                    <small>Powered by Hugging Face AI</small>
                </div>
            `;

            const rect = targetElement.getBoundingClientRect();
            this.safetyPopup.style.cssText = `
                position: fixed;
                top: ${rect.bottom + window.scrollY + 10}px;
                left: ${Math.max(10, rect.left + window.scrollX)}px;
                z-index: 10000;
                max-width: min(400px, calc(100vw - 20px));
            `;

            document.body.appendChild(this.safetyPopup);

            // Add event listeners
            this.safetyPopup.querySelector('.undo-close').addEventListener('click', () => {
                this.safetyPopup.remove();
            });

            this.safetyPopup.querySelector('.undo-use-alternative').addEventListener('click', () => {
                this.replaceText(targetElement, analysis.saferAlternative);
                this.safetyPopup.remove();
            });

            // Close popup when clicking outside
            setTimeout(() => {
                const clickHandler = (e) => {
                    if (this.safetyPopup && !this.safetyPopup.contains(e.target) && 
                        !targetElement.contains(e.target)) {
                        this.safetyPopup.remove();
                        document.removeEventListener('click', clickHandler);
                    }
                };
                document.addEventListener('click', clickHandler);
            }, 100);
        }

        replaceText(targetElement, newText) {
            if (targetElement.isContentEditable || targetElement.nodeName === 'DIV') {
                targetElement.textContent = newText;
                targetElement.dispatchEvent(new Event('input', { bubbles: true }));
                targetElement.dispatchEvent(new Event('change', { bubbles: true }));
            } else if (targetElement.nodeName === 'TEXTAREA') {
                targetElement.value = newText;
                targetElement.dispatchEvent(new Event('input', { bubbles: true }));
            }
            
            this.showConfirmation(targetElement, '✓ Alternative applied!');
        }

        showLoading(targetElement) {
            if (this.loading) this.loading.remove();
            
            this.loading = document.createElement('div');
            this.loading.className = 'undo-loading';
            this.loading.innerHTML = `
                <div style="display: flex; align-items: center; gap: 8px;">
                    <div class="undo-spinner"></div>
                    <span>Analyzing with AI...</span>
                </div>
            `;
            this.loading.style.cssText = `
                position: absolute;
                background: rgba(255, 255, 255, 0.95);
                padding: 8px 12px;
                border-radius: 6px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                z-index: 9999;
                font-size: 12px;
                color: #1a73e8;
                border: 1px solid #e0e0e0;
            `;
            
            const rect = targetElement.getBoundingClientRect();
            this.loading.style.top = `${rect.top + window.scrollY - 35}px`;
            this.loading.style.left = `${rect.left + window.scrollX}px`;
            
            document.body.appendChild(this.loading);
            
            // Auto-remove after 10 seconds
            setTimeout(() => {
                if (this.loading) {
                    this.loading.remove();
                    this.loading = null;
                }
            }, 10000);
        }

        showError(targetElement, message = 'Analysis failed. Check your Hugging Face token.') {
            const error = document.createElement('div');
            error.className = 'undo-error';
            error.textContent = message;
            error.style.cssText = `
                position: absolute;
                background: #fee;
                padding: 8px 12px;
                border-radius: 4px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                z-index: 9999;
                font-size: 12px;
                color: #c33;
                border: 1px solid #f5c6cb;
                max-width: 300px;
            `;
            
            const rect = targetElement.getBoundingClientRect();
            error.style.top = `${rect.top + window.scrollY - 35}px`;
            error.style.left = `${rect.left + window.scrollX}px`;
            
            document.body.appendChild(error);
            setTimeout(() => error.remove(), 5000);
        }

        showConfirmation(targetElement, message) {
            const confirm = document.createElement('div');
            confirm.className = 'undo-confirmation';
            confirm.textContent = message;
            confirm.style.cssText = `
                position: absolute;
                background: #d4edda;
                padding: 8px 12px;
                border-radius: 4px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                z-index: 9999;
                font-size: 12px;
                color: #155724;
                border: 1px solid #c3e6cb;
            `;
            
            const rect = targetElement.getBoundingClientRect();
            confirm.style.top = `${rect.top + window.scrollY - 35}px`;
            confirm.style.left = `${rect.left + window.scrollX}px`;
            
            document.body.appendChild(confirm);
            setTimeout(() => confirm.remove(), 3000);
        }

        async storeMessageHistory(text, analysis) {
            try {
                await fetch(`${this.serverUrl}/api/messages`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        original: text.substring(0, 500),
                        alternative: analysis.saferAlternative,
                        riskScore: analysis.riskScore,
                        riskLevel: analysis.riskLevel,
                        timestamp: new Date().toISOString(),
                        url: window.location.href,
                        source: 'huggingface'
                    })
                });
            } catch (error) {
                // Silent fail - server not required
            }
        }

        injectStyles() {
            // Styles are injected via content.css
            // Just check if they're loaded
            if (!document.querySelector('.undo-safety-popup')) {
                // Styles will be loaded by Chrome
            }
        }
    }

    // Initialize when page loads
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => new EmailSafetyAssistant());
    } else {
        new EmailSafetyAssistant();
    }
}