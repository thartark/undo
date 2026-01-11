// Fix: Prevent duplicate execution
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
            console.log('[Undo] Extension loaded');
            this.init();
        }

        async init() {
            chrome.storage.local.get(['undoHFToken'], (result) => {
                this.hfToken = result.undoHFToken;
                if (!this.hfToken) {
                    console.log('[Undo] No Hugging Face token found. Add one in popup.');
                }
            });
            this.setupObservers();
        }

        setupObservers() {
            if (window.location.hostname.includes('mail.google.com')) this.observeGmail();
            if (window.location.hostname.includes('linkedin.com')) this.observeLinkedIn();
        }

        observeGmail() {
            const observer = new MutationObserver((mutations) => {
                const composeBox = document.querySelector('[role="textbox"][aria-label*="Message"], [role="textbox"][aria-label*="Compose"]');
                if (composeBox && composeBox.textContent.trim().length > 30) {
                    clearTimeout(this.gmailTimeout);
                    this.gmailTimeout = setTimeout(() => {
                        this.analyzeMessage(composeBox.textContent, composeBox);
                    }, 1000);
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
                    }, 1000);
                }
            });
            observer.observe(document.body, { childList: true, subtree: true });
        }

        async analyzeMessage(text, targetElement) {
            if (this.isProcessing || !text.trim()) return;
            if (!this.hfToken) {
                this.showNoTokenMessage(targetElement);
                return;
            }
            this.isProcessing = true;
            this.showLoading(targetElement);
            try {
                // SIMPLIFIED FOR NOW: Use local analysis to avoid immediate API errors
                const analysis = this.getLocalAnalysis(text);
                this.showSafetyPopup(analysis, targetElement);
            } catch (error) {
                console.error('[Undo] Analysis error:', error);
                this.showError(targetElement, 'Analysis failed. Check token.');
            } finally {
                this.isProcessing = false;
            }
        }

        getLocalAnalysis(text) {
            // Simple rule-based analysis as a fallback/placeholder
            const score = Math.min([...text.matchAll(/urgent|asap|hate|stupid|!!+/gi)].length * 15, 95);
            const level = score > 70 ? 'high' : score > 40 ? 'medium' : 'low';
            return {
                riskScore: score,
                riskLevel: level,
                issues: level === 'high' ? ['Tone may be too strong'] : ['Looks good'],
                saferAlternative: "Hi,\n\n" + text.replace(/urgent/gi, 'important').replace(/asap/gi, 'when you can'),
                explanation: "AI-suggested improvements applied."
            };
        }

        showSafetyPopup(analysis, targetElement) {
            if (this.safetyPopup) this.safetyPopup.remove();
            this.safetyPopup = document.createElement('div');
            this.safetyPopup.className = 'undo-safety-popup';
            const riskColor = analysis.riskLevel === 'high' ? '#dc3545' : analysis.riskLevel === 'medium' ? '#ffc107' : '#28a745';
            this.safetyPopup.innerHTML = `
                <div class="undo-popup-header"><h3>Undo Safety Check</h3><span class="undo-close">×</span></div>
                <div class="undo-risk-indicator" style="border-left-color: ${riskColor}">
                    <div class="undo-risk-score"><span class="undo-score">${analysis.riskScore}</span> <span class="undo-risk-level">${analysis.riskLevel.toUpperCase()}</span></div>
                    <div class="undo-issues"><strong>Issues:</strong><ul><li>${analysis.issues[0]}</li></ul></div>
                </div>
                <div class="undo-alternative"><strong>Safer Alternative:</strong><div class="undo-safer-text">${analysis.saferAlternative}</div><button class="undo-use-alternative">Use This Version</button></div>
            `;
            const rect = targetElement.getBoundingClientRect();
            Object.assign(this.safetyPopup.style, {
                position: 'fixed', top: `${rect.bottom + window.scrollY + 10}px`, left: `${rect.left + window.scrollX}px`,
                zIndex: '10000', background: 'white', padding: '15px', borderRadius: '8px', boxShadow: '0 4px 12px rgba(0,0,0,0.15)', width: '350px'
            });
            document.body.appendChild(this.safetyPopup);
            this.safetyPopup.querySelector('.undo-close').onclick = () => this.safetyPopup.remove();
            this.safetyPopup.querySelector('.undo-use-alternative').onclick = () => {
                targetElement.textContent = analysis.saferAlternative;
                this.safetyPopup.remove();
                this.showConfirmation(targetElement, '✓ Alternative applied!');
            };
        }

        showLoading(targetElement) {
            const loading = document.createElement('div');
            loading.textContent = '🔍 Analyzing safety...';
            Object.assign(loading.style, {
                position: 'absolute', background: '#fff', padding: '8px 12px', borderRadius: '4px',
                boxShadow: '0 2px 10px rgba(0,0,0,0.1)', zIndex: '9999', fontSize: '12px', color: '#1a73e8'
            });
            const rect = targetElement.getBoundingClientRect();
            loading.style.top = `${rect.top + window.scrollY - 35}px`;
            loading.style.left = `${rect.left + window.scrollX}px`;
            document.body.appendChild(loading);
            setTimeout(() => loading.remove(), 1500);
        }

        showNoTokenMessage(targetElement) {
            const msg = document.createElement('div');
            msg.innerHTML = '🔑 <a href="#" style="color:#1a73e8;">Add Hugging Face Token</a> in popup.';
            Object.assign(msg.style, {
                position: 'absolute', background: '#fff3cd', padding: '8px 12px', borderRadius: '4px',
                boxShadow: '0 2px 10px rgba(0,0,0,0.1)', zIndex: '9999', fontSize: '12px', color: '#856404'
            });
            const rect = targetElement.getBoundingClientRect();
            msg.style.top = `${rect.top + window.scrollY - 35}px`;
            msg.style.left = `${rect.left + window.scrollX}px`;
            document.body.appendChild(msg);
            msg.querySelector('a').onclick = (e) => { e.preventDefault(); chrome.runtime.sendMessage({action: 'openPopup'}); };
            setTimeout(() => msg.remove(), 4000);
        }

        showError(targetElement, message) { /* Basic error display */ }
        showConfirmation(targetElement, message) { /* Basic confirmation display */ }
    }

    // Initialize
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', () => new EmailSafetyAssistant());
    } else {
        new EmailSafetyAssistant();
    }
}
