// basic content script: detects text areas
console.log("Undo extension active");

// observe text inputs
const observer = new MutationObserver(() => {
  document.querySelectorAll('textarea, input[type=text]').forEach(input => {
    if (!input.dataset.undoAttached) {
      input.dataset.undoAttached = "true";
      input.addEventListener("input", async () => {
        const text = input.value;
        try {
          const res = await fetch("http://localhost:3000/scan", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ message: text })
          });
          const data = await res.json();
          input.style.borderColor = data.riskScore > 3 ? "red" : "green";
        } catch (err) { console.log("Undo API error", err); }
      });
    }
  });
});
observer.observe(document.body, { childList: true, subtree: true });
