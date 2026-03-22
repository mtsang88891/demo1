# Local Technical Demonstrator

This folder contains the setup for a local AI-assisted Terraform generation
demonstrator built to accompany the written assessment.

## What it demonstrates

A developer types a plain-English infrastructure request into the Continue
chat panel in VS Code. The AI responds with complete Terraform module call
blocks sourced from the locally cloned CloudNation WAM public modules,
following CloudNation naming conventions and secure defaults.

**Example prompt:**

```
Create a hello world web application on Azure, westeurope, environment dev.
```

**Expected output:** one `.tf` file per resource type, using `CloudNationHQ/*`
module sources, written directly to `generated/`.

## Stack

| Component | Purpose |
|---|---|
| VS Code + Continue extension | AI IDE |
| Ollama (qwen2.5-coder:7b) | Local LLM — chat, edit, apply |
| Ollama (qwen2.5-coder:1.5b-base) | Local LLM — autocomplete |
| Ollama (nomic-embed-text) | Embeddings for codebase indexing |
| CloudNationHQ modules (cloned locally) | Grounded IaC context |

## Prerequisites

- Docker Desktop (WSL 2 backend, 8GB+ RAM allocated)
- Ollama installed and running
- VS Code installed
- Git installed

## Setup

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Initialize-WamEnvironment.ps1
```

The script will:
1. Clone all CloudNation `terraform-azure-*` modules locally
2. Install VS Code extensions
3. Write the Continue `config.yaml` with CloudNation rules
4. Generate the module index (`MODULES.md`)
5. Open the VS Code workspace

## Folder structure

```
poc/
  Initialize-WamEnvironment.ps1          Setup and update script
  cloudnation-wam.code-workspace VS Code workspace file
  
    MODULES.md                   Module index — loaded as context in Continue
    .continuerules               AI behaviour rules for this workspace
    PROMPTS.md                   Example prompts to use in Continue
    helloworld-app/              Sample generated Terraform output
      providers.tf
      variables.tf
      main.tf
      outputs.tf
    generated/                   AI-generated output (git-ignored)
```

## Notes

- `CloudNationHQ/` module clones are git-ignored — they are pulled fresh by
  `Initialize-WamEnvironment.ps1` from the public CloudNationHQ GitHub organisation
- `generated/` is git-ignored — it is the live output folder written to by
  the Continue agent