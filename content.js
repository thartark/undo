cat > content.js << 'EOF'
// Undo Extension - Clean Simple Version
console.log('Undo: Extension loaded');

if (!window.undoLoaded) {
    window.undoLoaded = true;
    
    let hfToken = null;
    let currentPopup = null;
    
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
        const observer = new MutationObserver(function(mutations) {
            // Look for Gmail compose box
            const composeBox = document.querySelector('[role="textbox"][aria-label*="Message"]') || 
                              document.querySelector('[role="textbox"][aria-label*="Compose"]') ||
                              document.querySelector('.Am[contenteditable="true"]');
            
            if (composeBox && composeBox.textContent && composeBox.textContent.length > 25) {
                // Wait a bit before analyzing
                clearTimeout(window.undoTimer);
                window.undoTimer = setTimeout(function() {
                    analyzeText(composeBox.textContent, composeBox);
                }, 1000);
            }
        });
        
        observer.observe(document.body, { 
            childList: true, 
            subtree: true, 
            characterData: true 
        });
    }
    
    // Start watching
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', watchForTyping);
    } else {
        watchForTyping();
    }
    
    function analyzeText(text, targetElement) {
        console.log('Undo: Analyzing text');
        
        if (!hfToken) {
            showTokenMessage();
            return;
        }
        
        // Remove existing popup
        if (currentPopup) {
            currentPopup.remove();
            currentPopup = null;
        }
        
        // Show loading
        showLoading();
        
        // Analyze after delay
        setTimeout(function() {
            // Remove loading
            const loading = document.querySelector('.undo-loading');
            if (loading) loading.remove();
            
            // Create safety analysis
            const analysis = createAnalysis(text);
            showSafetyPopup(analysis, targetElement);
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
        safer = safer.replace(/urgent/gi, 'important');
        safer = safer.replace(/asap/gi, 'when convenient');
        safer = safer.replace(/!!!+/g, '!');
        
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
        const msg = document.createElement('div');
        msg.innerHTML = '<div style="background:#fff3cd;color:#856404;padding:12px 16px;border-radius:8px;border:1px solid #ffeaa7;margin:10px;font-family:Arial;">🔑 Add token in extension popup</div>';
        msg.style.cssText = 'position:fixed;top:20px;right:20px;z-index:999999;';
        
        document.body.appendChild(msg);
        setTimeout(function() {
            if (msg.parentNode) msg.remove();
        }, 4000);
    }
    
    function showLoading() {
        const loading = document.createElement('div');
        loading.innerHTML = '<div style="display:flex;align-items:center;gap:10px;background:white;padding:12px 16px;border-radius:8px;border:1px solid #e0e0e0;box-shadow:0 2px 8px rgba(0,0,0,0.1);"><div style="width:16px;height:16px;border:2px solid #f3f3f3;border-top:2px solid #1a73e8;border-radius:50%;animation:spin 1s linear infinite;"></div>Analyzing...</div>';
        loading.style.cssText = 'position:fixed;top:20px;right:20px;z-index:999998;font-family:Arial;';
        
        // Add spin animation
        if (!document.querySelector('#undo-spin')) {
            const style = document.createElement('style');
            style.id = 'undo-spin';
            style.textContent = '@keyframes spin {0%{transform:rotate(0deg);}100%{transform:rotate(360deg);}}';
            document.head.appendChild(style);
        }
        
        document.body.appendChild(loading);
        loading.className = 'undo-loading';
        return loading;
    }
    
    function showSafetyPopup(analysis, targetElement) {
        // Remove existing
        if (currentPopup) currentPopup.remove();
        
        // Create popup
        currentPopup = document.createElement('div');
        
        // Set color based on risk
        let color = '#28a745'; // green
        if (analysis.level === 'medium') color = '#ffc107'; // yellow
        if (analysis.level === 'high') color = '#dc3545'; // red
        
        currentPopup.innerHTML = `
            <div style="width:360px;background:white;border-radius:10px;box-shadow:0 6px 20px rgba(0,0,0,0.15);font-family:Arial;overflow:hidden;">
                <div style="background:#1a73e8;color:white;padding:16px 20px;display:flex;justify-content:space-between;align-items:center;">
                    <div style="font-weight:600;font-size:16px;">🔒 Undo Safety Check</div>
                    <div style="cursor:pointer;font-size:20px;" onclick="this.parentNode.parentNode.parentNode.remove()">×</div>
                </div>
                
                <div style="padding:20px;border-left:4px solid ${color};">
                    <div style="display:flex;align-items:center;gap:15px;margin-bottom:15px;">
                        <div style="font-size:32px;font-weight:bold;">${analysis.score}</div>
                        <div style="background:#f8f9fa;padding:6px 12px;border-radius:12px;font-size:12px;font-weight:600;color:#333;">
                            ${analysis.level.toUpperCase()} RISK
                        </div>
                    </div>
                    
                    <div style="margin-bottom:15px;">
                        <div style="font-weight:600;margin-bottom:8px;color:#333;">Issues found:</div>
                        <ul style="margin:0;padding-left:20px;color:#666;">
                            ${analysis.issues.map(issue => `<li>${issue}</li>`).join('')}
                        </ul>
                    </div>
                </div>
                
                <div style="padding:20px;background:#f8f9fa;border-top:1px solid #eee;">
                    <div style="font-weight:600;margin-bottom:10px;color:#333;">Safer version:</div>
                    <div style="background:white;padding:15px;border-radius:6px;border:1px solid #ddd;margin-bottom:15px;font-size:14px;line-height:1.5;max-height:150px;overflow-y:auto;">
                        ${analysis.saferText}
                    </div>
                    
                    <button style="width:100%;padding:12px;background:#1a73e8;color:white;border:none;border-radius:6px;font-weight:600;cursor:pointer;font-size:14px;">
                        Use This Version
                    </button>
                </div>
                
                <div style="padding:12px 20px;background:#f1f3f4;color:#666;font-size:12px;text-align:center;">
                    ${analysis.explanation}
                </div>
            </div>
        `;
        
        currentPopup.style.cssText = 'position:fixed;top:80px;right:20px;z-index:999997;';
        
        document.body.appendChild(currentPopup);
        
        // Add click handler for button
        const button = currentPopup.querySelector('button');
        button.onclick = function() {
            if (targetElement && targetElement.textContent !== undefined) {
                targetElement.textContent = analysis.saferText;
                showMessage('Safer version applied!', 'success');
            }
            currentPopup.remove();
            currentPopup = null;
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
            padding: 12px 20px;
            border-radius: 8px;
            z-index: 999999;
            font-family: Arial;
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        `;
        
        document.body.appendChild(msg);
        setTimeout(function() {
            if (msg.parentNode) msg.remove();
        }, 3000);
    }
}
EOF

