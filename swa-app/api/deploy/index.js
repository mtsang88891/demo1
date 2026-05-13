const { DefaultAzureCredential } = require("@azure/identity");

module.exports = async function (context, req) {
  try {
    const { name, description, terraformCode } = req.body || {};

    if (!name || !description || !terraformCode) {
      context.res = {
        status: 400,
        body: { error: "Missing required fields: name, description, terraformCode" }
      };
      return;
    }

    // Validate Terraform code contains expected patterns
    if (!terraformCode.toLowerCase().includes("resource") && !terraformCode.toLowerCase().includes("module")) {
      context.res = {
        status: 400,
        body: { error: "Invalid Terraform code: must contain resource or module declarations" }
      };
      return;
    }

    // Return deployment info with terraform code
    const deploymentId = `terraform-${Date.now()}-${Math.random().toString(36).substr(2, 5)}`;
    
    context.res = {
      status: 200,
      body: {
        status: "deployment_code_generated",
        name: name,
        description: description,
        deployment_id: deploymentId,
        terraform_code: terraformCode,
        message: "Terraform code generated successfully. To deploy, save this code locally and run: terraform init && terraform plan && terraform apply",
        instructions: [
          "1. Copy the terraform code provided above",
          "2. Create a new directory for your infrastructure: mkdir my-infrastructure && cd my-infrastructure",
          "3. Create a file named main.tf and paste the code",
          "4. Initialize Terraform: terraform init",
          "5. Plan the deployment: terraform plan",
          "6. Apply the configuration: terraform apply",
          "7. Confirm the deployment when prompted"
        ],
        deployment_timestamp: new Date().toISOString()
      }
    };
  } catch (err) {
    context.res = {
      status: 500,
      body: { error: err.message }
    };
  }
};
