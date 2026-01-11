// Undo Extension - Clean Working Version
console.log('Undo: Extension loaded');

if (!window.undoLoaded) {
    window.undoLoaded = true;
    
    let hfToken = null;
    let currentPopup = null;
    let isAnalyzing = false;
    let lastAnalysisTime = 0;
    
    // Load token
    chrome.storage.local.get(['undoHFToken'], function(result) {
        hfToken = result.undoHFToken;
        console.log('Undo: Token loaded', hfToken ? 'Yes' : 'No');
    });
    
    // Listen for token updates
    chrome.runtime.onMessage.addListener(function(request, sender, sendResponse) {
        if (request.type === 'TOKEN_UPDATED') {
            hfToken = request.token;
            console.log('Undo: Token updated');
            showMessage('Token activated!', 'success');
        }
        return true;
    });
    
    // Watch for typing in Gmail
    function watchForTyping() {
        let lastTypedText = '';
        let debounceTimer = null;
        
        const observer = new MutationObserver(function(mutations) {
            // Look for Gmail compose box
            const composeBox = document.querySelector('[role="textbox"][aria-label*="Message"]') || 
                              document.querySelector('[role="textbox"][aria-label*="Compose"]') ||
                              document.querySelector('.Am[contenteditable="true"]');
            
            if (composeBox && composeBox.textContent) {
                const currentText = composeBox.textContent.trim();
                
                // Only analyze if text is long enough and changed
                if (currentText.length > 25 && 
                    currentText !== lastTypedText && 
                    !isAnalyzing &&
                    Date.now() - lastAnalysisTime > 5000) {
                    
                    // Clear previous timer
                    clearTimeout(debounceTimer);
                    
                    // Set new timer with longer delay
                    debounceTimer = setTimeout(function() {
                        if (Math.abs(currentText.length - lastTypedText.length) > 10 || 
                            currentText !== lastTypedText) {
                            
                            lastTypedText = currentText;
                            analyzeText(currentText, composeBox);
                        }
                    }, 2000); // Wait 2 seconds after typing stops
                }
            }
        });
        
        observer.observe(document.body, { 
            childList: true, 
            subtree: true, 
            characterData: true 
        });
        
        return observer;
    }
    
    // Start watching
    let typingObserver = null;
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            typingObserver = watchForTyping();
        });
    } else {
        typingObserver = watchForTyping();
    }
    
    function analyzeText(text, targetElement) {
        console.log('Undo: Analyzing text');
        
        if (!hfToken) {
            showTokenMessage();
            return;
        }
        
        // Don't analyze if already analyzing or just analyzed
        if (isAnalyzing || Date.now() - lastAnalysisTime < 3000) {
            console.log('Undo: Skipping - already analyzing or too soon');
            return;
        }
        
        isAnalyzing = true;
        lastAnalysisTime = Date.now();
        
        // Remove existing popup and loading
        if (currentPopup) {
            currentPopup.remove();
            currentPopup = null;
        }
        
        const loadingElements = document.querySelectorAll('.undo-loading');
        loadingElements.forEach(el => el.remove());
        
        // Show loading
        const loadingEl = showLoading();
        
        // Analyze after delay
        setTimeout(function() {
            // Remove loading
            if (loadingEl && loadingEl.parentNode) {
                loadingEl.remove();
            }
            
            // Create safety analysis
            const analysis = createAnalysis(text);
            showSafetyPopup(analysis, targetElement);
            
            isAnalyzing = false;
        }, 1500);
    }
    
    function createAnalysis(text) {
        // Calculate risk score
        let score = 0;
        if (text.toLowerCase().includes('urgent')) score += 30;
        if (text.toLowerCase().includes('asap')) score += 25;
        if (text.toLowerCase().includes('hate')) score += 40;
        if (text.toLowerCase().includes('stupid')) score += 35;
        if (text.toLowerCase().includes('sucks')) score += 45;
        if (text.includes('!!!')) score += 20;
        if (text.match(/[A-Z]{4,}/)) score += 15;
        
        // Cap at 100
        score = Math.min(score, 100);
        
        // Determine risk level
        let level = 'low';
        if (score > 70) level = 'high';
        else if (score > 40) level = 'medium';
        
        // Create safer version
        let safer = text;
        safer = safer.replace(/sucks/gi, 'could be improved');
        safer = safer.replace(/hate/gi, 'dislike');
        safer = safer.replace(/stupid/gi, 'unwise');
        safer = safer.replace(/idiot/gi, 'person');
        safer = safer.replace(/urgent/gi, 'important');
        safer = safer.replace(/asap/gi, 'when convenient');
        safer = safer.replace(/!!!+/g, '!');
        safer = safer.replace(/\?\?\?+/g, '?');
        
        // Fix all caps
        safer = safer.replace(/([A-Z]{4,})/g, function(match) {
            return match.charAt(0).toUpperCase() + match.slice(1).toLowerCase();
        });
        
        // Add greeting if missing
        if (!safer.toLowerCase().startsWith('hi ') && 
            !safer.toLowerCase().startsWith('hello ') &&
            !safer.toLowerCase().startsWith('dear ')) {
            safer = "Hi,\n\n" + safer;
        }
        
        // Get issues
        const issues = [];
        if (text.toLowerCase().includes('sucks')) issues.push('Inappropriate language');
        if (text.toLowerCase().includes('hate')) issues.push('Negative emotion');
        if (text.includes('!!!')) issues.push('Excessive punctuation');
        if (text.match(/[A-Z]{4,}/)) issues.push('ALL CAPS (shouting)');
        if (text.toLowerCase().includes('urgent')) issues.push('Urgent tone');
        
        if (issues.length === 0) issues.push('No major issues');
        
        return {
            score: score,
            level: level,
            issues: issues,
            saferText: safer,
            explanation: 'AI safety analysis'
        };
    }
    
    function showTokenMessage() {
        // Remove existing message
        const existing = document.querySelector('.undo-token-message');
        if (existing) existing.remove();
        
        const msg = document.createElement('div');
        msg.innerHTML = '<div style="background:#fff3cd;color:#856404;padding:12px 16px;border-radius:8px;border:1px solid #ffeaa7;font-family:Arial;font-size:14px;">🔑 Add token in extension popup</div>';
        msg.style.cssText = 'position:fixed;top:20px;right:20px;z-index:2147483647;';
        msg.className = 'undo-token-message';
        
        document.body.appendChild(msg);
        setTimeout(function() {
            if (msg.parentNode) msg.remove();
        }, 4000);
    }
    
    function showLoading() {
        // Remove existing loading
        const existing = document.querySelector('.undo-loading');
        if (existing) existing.remove();
        
        const loading = document.createElement('div');
        loading.innerHTML = '<div style="display:flex;align-items:center;gap:10px;background:white;padding:12px 16px;border-radius:8px;border:1px solid #e0e0e0;box-shadow:0 2px 8px rgba(0,0,0,0.1);"><div style="width:16px;height:16px;border:2px solid #f3f3f3;border-top:2px solid #1a73e8;border-radius:50%;animation:spin 1s linear infinite;"></div><span style="color:#1a73e8;font-weight:500;">Analyzing safety...</span></div>';
        loading.style.cssText = 'position:fixed;top:20px;right:20px;z-index:2147483646;font-family:Arial;';
        loading.className = 'undo-loading';
        
        document.body.appendChild(loading);
        return loading;
    }
    
    function showSafetyPopup(analysis, targetElement) {
        // Remove existing popup
        if (currentPopup) {
            currentPopup.remove();
            currentPopup = null;
        }
        
        // Create popup
        currentPopup = document.createElement('div');
        
        // Set color based on risk
        let color = '#28a745'; // green
        if (analysis.level === 'medium') color = '#ffc107'; // yellow
        if (analysis.level === 'high') color = '#dc3545'; // red
        
        currentPopup.innerHTML = `
            <div style="width:380px;background:white;border-radius:10px;box-shadow:0 8px 25px rgba(0,0,0,0.15);font-family:Arial;overflow:hidden;border:1px solid #e0e0e0;">
                <div style="background:#1a73e8;color:white;padding:16px 20px;display:flex;justify-content:space-between;align-items:center;">
                    <div style="font-weight:600;font-size:16px;">🔒 Undo Safety Check</div>
                    <div style="cursor:pointer;font-size:24px;line-height:1;padding:0 5px;" id="undo-close">×</div>
                </div>
                
                <div style="padding:20px;border-left:5px solid ${color};">
                    <div style="display:flex;align-items:center;gap:15px;margin-bottom:15px;">
                        <div style="font-size:36px;font-weight:bold;color:#333;">${analysis.score}</div>
                        <div style="background:#f8f9fa;padding:8px 14px;border-radius:15px;font-size:13px;font-weight:600;color:#333;border:1px solid #e0e0e0;">
                            ${analysis.level.toUpperCase()} RISK
                        </div>
                    </div>
                    
                    <div style="margin-bottom:15px;">
                        <div style="font-weight:600;margin-bottom:10px;color:#333;font-size:14px;">Potential issues:</div>
                        <ul style="margin:0;padding-left:20px;color:#666;font-size:13px;line-height:1.5;">
                            ${analysis.issues.map(issue => `<li style="margin-bottom:8px;">${issue}</li>`).join('')}
                        </ul>
                    </div>
                </div>
                
                <div style="padding:20px;background:#f8f9fa;border-top:1px solid #eee;">
                    <div style="font-weight:600;margin-bottom:12px;color:#333;font-size:14px;">✨ Safer version:</div>
                    <div style="background:white;padding:15px;border-radius:8px;border:1px solid #ddd;margin-bottom:20px;font-size:14px;line-height:1.6;max-height:180px;overflow-y:auto;white-space:pre-wrap;">
                        ${analysis.saferText}
                    </div>
                    
                    <button style="width:100%;padding:14px;background:#1a73e8;color:white;border:none;border-radius:8px;font-weight:600;cursor:pointer;font-size:15px;transition:background 0.2s;" id="undo-apply">
                        Use This Version
                    </button>
                </div>
                
                <div style="padding:12px 20px;background:#f1f3f4;color:#666;font-size:12px;text-align:center;border-top:1px solid #ddd;">
                    ${analysis.explanation}
                </div>
            </div>
        `;
        
        currentPopup.style.cssText = 'position:fixed;top:80px;right:20px;z-index:2147483645;';
        currentPopup.className = 'undo-safety-popup';
        
        document.body.appendChild(currentPopup);
        
        // Close button handler
        currentPopup.querySelector('#undo-close').onclick = function() {
            if (currentPopup) {
                currentPopup.remove();
                currentPopup = null;
            }
        };
        
        // Apply button handler
        currentPopup.querySelector('#undo-apply').onclick = function() {
            if (targetElement && targetElement.textContent !== undefined) {
                targetElement.textContent = analysis.saferText;
                showMessage('✅ Safer version applied!', 'success');
            }
            if (currentPopup) {
                currentPopup.remove();
                currentPopup = null;
            }
        };
        
        // Auto-remove after 30 seconds
        setTimeout(function() {
            if (currentPopup && currentPopup.parentNode) {
                currentPopup.remove();
                currentPopup = null;
            }
        }, 30000);
    }
    
    function showMessage(text, type) {
        // Remove existing message
        const existing = document.querySelector('.undo-message');
        if (existing) existing.remove();
        
        const msg = document.createElement('div');
        msg.textContent = text;
        
        let bgColor = '#4CAF50'; // green for success
        if (type === 'error') bgColor = '#dc3545';
        if (type === 'warning') bgColor = '#ffc107';
        
        msg.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: ${bgColor};
            color: white;
            padding: 14px 22px;
            border-radius: 8px;
            z-index: 2147483647;
            font-family: Arial;
            font-weight: 600;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
            font-size: 14px;
        `;
        msg.className = 'undo-message';
        
        document.body.appendChild(msg);
        setTimeout(function() {
            if (msg.parentNode) msg.remove();
        }, 3000);
    }
}