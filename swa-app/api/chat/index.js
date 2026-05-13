const { DefaultAzureCredential, ManagedIdentityCredential, getBearerTokenProvider } = require("@azure/identity");
const { AzureOpenAI } = require("openai");

const MAX_MESSAGE_CHARS = 4000;
const MAX_RULES_CHARS = 2000;
const TOKEN_SCOPE = "https://cognitiveservices.azure.com/.default";

function buildCredential() {
  // In Azure App Service / Functions, use system-assigned managed identity
  // ManagedIdentityCredential without parameters uses the system-assigned identity
  return new ManagedIdentityCredential();
}

function getClient() {
  const endpoint = process.env.OPENAI_ENDPOINT;
  if (!endpoint) {
    throw new Error("OPENAI_ENDPOINT is required.");
  }

  const credential = buildCredential();
  const azureADTokenProvider = getBearerTokenProvider(credential, TOKEN_SCOPE);

  return new AzureOpenAI({
    endpoint,
    apiVersion: "2024-10-21",
    azureADTokenProvider
  });
}

module.exports = async function (context, req) {
  try {
    const deployment = process.env.OPENAI_DEPLOYMENT_NAME;
    if (!deployment) {
      context.res = {
        status: 500,
        body: { error: "OPENAI_DEPLOYMENT_NAME is not configured." }
      };
      return;
    }

    const body = req.body || {};
    const userMessage = typeof body.message === "string" ? body.message.trim() : "";
    const runtimeRules = typeof body.runtimeRules === "string" ? body.runtimeRules.trim() : "";

    if (!userMessage) {
      context.res = {
        status: 400,
        body: { error: "message is required." }
      };
      return;
    }

    if (userMessage.length > MAX_MESSAGE_CHARS) {
      context.res = {
        status: 400,
        body: { error: `message exceeds ${MAX_MESSAGE_CHARS} characters.` }
      };
      return;
    }

    if (runtimeRules.length > MAX_RULES_CHARS) {
      context.res = {
        status: 400,
        body: { error: `runtimeRules exceeds ${MAX_RULES_CHARS} characters.` }
      };
      return;
    }

    const baseSystemPrompt = process.env.OPENAI_SYSTEM_PROMPT || "You are a helpful assistant.";
    const effectiveSystemPrompt = runtimeRules
      ? `${baseSystemPrompt}\n\nAdditional runtime rules:\n${runtimeRules}`
      : baseSystemPrompt;

    const client = getClient();

    const completion = await client.chat.completions.create({
      model: deployment,
      temperature: 0.2,
      max_tokens: 600,
      messages: [
        { role: "system", content: effectiveSystemPrompt },
        { role: "user", content: userMessage }
      ]
    });

    const answer = completion.choices?.[0]?.message?.content || "No response received.";

    context.res = {
      status: 200,
      headers: {
        "Content-Type": "application/json"
      },
      body: {
        answer,
        model: deployment
      }
    };
  } catch (error) {
    context.log.error("Chat API failure", error);
    context.res = {
      status: 500,
      body: {
        error: "Failed to process chat request.",
        details: error.message
      }
    };
  }
};
