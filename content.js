// TextCraft Pro - Content Script
console.log('TextCraft Pro loaded');

class TextCraft {
    constructor() {
        this.history = [];
        this.position = -1;
        this.maxHistory = 100;
        this.autoSave = true;
        
        this.init();
    }
    
    init() {
        // Load history from storage
        chrome.storage.local.get(['textcraft_history'], (result) => {
            if (result.textcraft_history) {
                this.history = result.textcraft_history;
                this.position = this.history.length - 1;
            }
        });
        
        // Listen for text changes
        document.addEventListener('input', this.handleInput.bind(this), true);
        
        // Listen for messages from popup
        chrome.runtime.onMessage.addListener(this.handleMessage.bind(this));
        
        console.log('TextCraft Pro initialized');
    }
    
    handleInput(event) {
        const element = event.target;
        if (this.isTextElement(element) && this.autoSave) {
            this.saveState(element.value, element);
        }
    }
    
    handleMessage(request, sender, sendResponse) {
        const element = this.getActiveTextElement();
        
        switch(request.action) {
            case 'undo':
                this.undo(element);
                sendResponse({success: true});
                break;
                
            case 'redo':
                this.redo(element);
                sendResponse({success: true});
                break;
                
            case 'transform':
                this.transformText(element, request.data.type);
                sendResponse({success: true});
                break;
                
            case 'getStats':
                const stats = this.getTextStats(element);
                sendResponse(stats);
                break;
                
            default:
                sendResponse({success: false, error: 'Unknown action'});
        }
        
        return true; // Keep message channel open for async response
    }
    
    isTextElement(element) {
        return (
            element.tagName === 'TEXTAREA' ||
            (element.tagName === 'INPUT' && element.type === 'text') ||
            (element.tagName === 'INPUT' && element.type === 'email') ||
            (element.tagName === 'INPUT' && element.type === 'password') ||
            (element.tagName === 'INPUT' && element.type === 'search') ||
            (element.tagName === 'INPUT' && element.type === 'url') ||
            element.isContentEditable
        );
    }
    
    getActiveTextElement() {
        const active = document.activeElement;
        if (this.isTextElement(active)) {
            return active;
        }
        // Fallback to first textarea
        return document.querySelector('textarea, input[type="text"]');
    }
    
    saveState(text, element) {
        // Don't save if text hasn't changed
        if (this.history.length > 0 && this.history[this.position] === text) {
            return;
        }
        
        // Remove future history if we're not at the end
        this.history = this.history.slice(0, this.position + 1);
        
        // Add new state
        this.history.push(text);
        this.position++;
        
        // Limit history size
        if (this.history.length > this.maxHistory) {
            this.history.shift();
            this.position--;
        }
        
        // Save to storage
        chrome.storage.local.set({textcraft_history: this.history});
    }
    
    undo(element) {
        if (this.position > 0 && element) {
            this.position--;
            const text = this.history[this.position];
            this.setText(element, text);
        }
    }
    
    redo(element) {
        if (this.position < this.history.length - 1 && element) {
            this.position++;
            const text = this.history[this.position];
            this.setText(element, text);
        }
    }
    
    setText(element, text) {
        if (element.tagName === 'TEXTAREA' || element.tagName === 'INPUT') {
            element.value = text;
        } else if (element.isContentEditable) {
            element.textContent = text;
        }
        
        // Trigger input event
        element.dispatchEvent(new Event('input', {bubbles: true}));
        element.dispatchEvent(new Event('change', {bubbles: true}));
    }
    
    transformText(element, type) {
        if (!element) return;
        
        let currentText = element.tagName === 'TEXTAREA' || element.tagName === 'INPUT' 
            ? element.value 
            : element.textContent;
        
        let transformedText = currentText;
        
        switch(type) {
            case 'uppercase':
                transformedText = currentText.toUpperCase();
                break;
            case 'lowercase':
                transformedText = currentText.toLowerCase();
                break;
            case 'titlecase':
                transformedText = currentText.replace(/\b\w/g, char => char.toUpperCase());
                break;
        }
        
        this.setText(element, transformedText);
        this.saveState(transformedText, element);
    }
    
    getTextStats(element) {
        if (!element) {
            return {words: 0, chars: 0, lines: 0};
        }
        
        const text = element.tagName === 'TEXTAREA' || element.tagName === 'INPUT' 
            ? element.value 
            : element.textContent;
        
        const words = text.trim() ? text.trim().split(/\s+/).length : 0;
        const chars = text.length;
        const lines = text.split('\n').length;
        
        return {words, chars, lines};
    }
}

// Initialize TextCraft Pro
const textcraft = new TextCraft();

// Make it globally available for debugging
window.TextCraftPro = textcraft;
