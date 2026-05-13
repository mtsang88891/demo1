const sendButton = document.getElementById("send");
const promptInput = document.getElementById("prompt");
const rulesInput = document.getElementById("rules");
const statusOutput = document.getElementById("status");
const responseOutput = document.getElementById("response");

async function sendPrompt() {
  const message = promptInput.value.trim();
  const runtimeRules = rulesInput.value.trim();

  if (!message) {
    statusOutput.textContent = "Enter a message first.";
    return;
  }

  sendButton.disabled = true;
  statusOutput.textContent = "Sending...";

  try {
    const res = await fetch("/api/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ message, runtimeRules })
    });

    const payload = await res.json();

    if (!res.ok) {
      throw new Error(payload.error || "Request failed.");
    }

    responseOutput.textContent = payload.answer || "No answer.";
    statusOutput.textContent = `Model deployment: ${payload.model}`;
  } catch (error) {
    statusOutput.textContent = `Error: ${error.message}`;
  } finally {
    sendButton.disabled = false;
  }
}

sendButton.addEventListener("click", sendPrompt);
