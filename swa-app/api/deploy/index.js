const { DefaultAzureCredential } = require("@azure/identity");
const { exec } = require("child_process");
const fs = require("fs");
const path = require("path");
const { promisify } = require("util");

const execPromise = promisify(exec);

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

    // Create deployment directory
    const tempDir = path.join("/tmp", `terraform-${Date.now()}`);
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    // Write Terraform files
    const mainTfPath = path.join(tempDir, "main.tf");
    fs.writeFileSync(mainTfPath, terraformCode);

    // Create variables.tf for custom variables
    const variablesTfPath = path.join(tempDir, "variables.tf");
    const variablesTf = `
variable "environment" {
  default = "dev"
}

variable "location" {
  default = "westeurope"
}
`;
    fs.writeFileSync(variablesTfPath, variablesTf);

    // Create terraform.tfvars
    const tfvarPath = path.join(tempDir, "terraform.tfvars");
    const tfvar = `
environment = "dev"
location    = "westeurope"
`;
    fs.writeFileSync(tfvarPath, tfvar);

    // Attempt to execute terraform (if available)
    try {
      // Initialize Terraform
      const { stdout: initOutput } = await execPromise(`cd ${tempDir} && terraform init 2>&1`);
      
      // Plan deployment
      const { stdout: planOutput } = await execPromise(`cd ${tempDir} && terraform plan -out=tfplan 2>&1`);
      
      // Apply deployment
      const { stdout: applyOutput } = await execPromise(`cd ${tempDir} && terraform apply -auto-approve tfplan 2>&1`);

      // Return success with plan details
      context.res = {
        status: 200,
        body: {
          status: "deployment_initiated",
          name: name,
          description: description,
          deployment_id: `terraform-${Date.now()}`,
          terraform_init: initOutput.substring(0, 500),
          terraform_plan: planOutput.substring(0, 500),
          terraform_apply: applyOutput.substring(0, 500),
          temp_directory: tempDir,
          message: "Terraform deployment initiated. Check Azure Portal for resource status."
        }
      };
    } catch (execError) {
      // If terraform is not available or fails, return the code with instructions
      context.res = {
        status: 200,
        body: {
          status: "terraform_code_generated",
          name: name,
          description: description,
          terraform_code: terraformCode,
          message: "Terraform code generated. To deploy, run: terraform init && terraform plan && terraform apply",
          instructions: "1. Copy the terraform code above\n2. Create a directory for your deployment\n3. Paste the code into main.tf\n4. Run 'terraform init'\n5. Run 'terraform plan'\n6. Run 'terraform apply'",
          error_details: execError.message
        }
      };
    }
  } catch (err) {
    context.res = {
      status: 500,
      body: { error: err.message }
    };
  }
};
