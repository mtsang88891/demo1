const sendButton = document.getElementById("send");
const promptInput = document.getElementById("prompt");
const rulesInput = document.getElementById("rules");
const statusOutput = document.getElementById("status");
const responseOutput = document.getElementById("response");
const deployButton = document.getElementById("deploy");
const deployNameInput = document.getElementById("deployment-name");
const deployDescriptionInput = document.getElementById("deployment-description");
const deployStatusOutput = document.getElementById("deploy-status");
const deployResponseOutput = document.getElementById("deploy-response");

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

async function deployInfrastructure() {
  const deploymentName = deployNameInput.value.trim();
  const description = deployDescriptionInput.value.trim();
  const terraformCode = responseOutput.textContent;

  if (!deploymentName || !description) {
    deployStatusOutput.textContent = "Enter deployment name and description first.";
    return;
  }

  if (!terraformCode || terraformCode === "No response yet.") {
    deployStatusOutput.textContent = "Generate infrastructure suggestion first by sending a prompt.";
    return;
  }

  deployButton.disabled = true;
  deployStatusOutput.textContent = "Deploying...";

  try {
    const res = await fetch("/api/deploy", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        name: deploymentName,
        description: description,
        terraformCode: terraformCode
      })
    });

    const payload = await res.json();

    if (!res.ok) {
      throw new Error(payload.error || "Deployment failed.");
    }

    deployResponseOutput.textContent = JSON.stringify(payload.result, null, 2) || "Deployment completed.";
    deployStatusOutput.textContent = "Deployment successful!";
  } catch (error) {
    deployStatusOutput.textContent = `Error: ${error.message}`;
    deployResponseOutput.textContent = error.message;
  } finally {
    deployButton.disabled = false;
  }
}

sendButton.addEventListener("click", sendPrompt);
deployButton.addEventListener("click", deployInfrastructure);
