# Example prompts to use in the Continue chat panel
# Copy and paste these into Continue to test the setup.

## Hello World web app (App Service equivalent)

@file MODULES.md
Create an app service showing hello world. Use the correct CloudNation WAM
module for a containerised web application. Include all required Terraform
files: main.tf, variables.tf, outputs.tf, providers.tf.
Use resource group westeurope, environment dev.


## Secure storage account

@folder C:\DEVOPS\CloudNation\CloudNationHQ\terraform-azure-sa
Create a secure storage account for a dev environment in West Europe.
Enable blob soft-delete 14 days, network deny-by-default, TLS 1.2.
Follow CloudNation naming conventions.


## Key Vault with RBAC

@folder C:\DEVOPS\CloudNation\CloudNationHQ\terraform-azure-kv
Create a Key Vault for a production workload. Enable RBAC authorization,
purge protection, soft delete 90 days, deny public access.


## Full web app stack

@file MODULES.md
Create a complete web application stack for a hello world app with:
- Container App (web frontend)
- Key Vault (secrets)
- Storage Account (static assets)
- Virtual Network with subnet
All in West Europe, dev environment, following CloudNation naming conventions.
