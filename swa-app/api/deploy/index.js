const { DefaultAzureCredential } = require("@azure/identity");
const { ResourceManagementClient } = require("@azure/arm-resources");

module.exports = async function (context, req) {
  // Simple admin check (replace with better auth in production)
  if (req.headers["x-admin-secret"] !== process.env.ADMIN_SECRET) {
    context.res = { status: 403, body: { error: "Forbidden" } };
    return;
  }

  const { subscriptionId, resourceGroup, resourceType, resourceName, location, parameters } = req.body || {};
  if (!subscriptionId || !resourceGroup || !resourceType || !resourceName || !location) {
    context.res = { status: 400, body: { error: "Missing required fields." } };
    return;
  }

  try {
    const credential = new DefaultAzureCredential();
    const client = new ResourceManagementClient(credential, subscriptionId);

    // Ensure resource group exists
    await client.resourceGroups.createOrUpdate(resourceGroup, { location });

    // Deploy resource (generic)
    const result = await client.resources.beginCreateOrUpdateAndWait(
      resourceGroup,
      '', // resource provider namespace (e.g., 'Microsoft.Storage')
      '', // parent resource path
      resourceType, // resource type (e.g., 'storageAccounts')
      resourceName,
      '2022-09-01', // API version (should be parameterized per resource)
      parameters
    );

    context.res = { status: 200, body: { result } };
  } catch (err) {
    context.res = { status: 500, body: { error: err.message } };
  }
};
