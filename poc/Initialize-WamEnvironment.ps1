#Requires -Version 5.1
<#
.SYNOPSIS
    CloudNation WAM PoC — Continue + Ollama + Terraform Module Context Setup
    
.DESCRIPTION
    Sets up VS Code + Continue to accept plain-English infrastructure prompts
    and respond with real Terraform module call blocks sourced from the
    CloudNation public module library cloned locally.

    When a developer types into Continue:
        "create an app service showing hello world"
    
    The AI responds with a complete main.tf using real CloudNation module
    blocks such as terraform-azure-ca (Container Apps) or terraform-azure-func,
    grounded in the actual variables.tf and README from the local clone.

.NOTES
    Confirmed on your machine:
      - kind.exe      C:\DEVOPS\kind.exe
      - rad.exe       C:\DEVOPS\rad.exe
      - kubectl       Docker Desktop
      - cluster       radius  (context: kind-radius)
      - workspace     default (environment: default)
      - Ollama models llama3.1:8b  qwen2.5-coder:1.5b-base  nomic-embed-text

    Run as Administrator:
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
      .\setup-wam-context.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── paths ─────────────────────────────────────────────────────────────────────
$ROOT      = "C:\DEVOPS\CloudNation"
$MODULES   = "$ROOT\CloudNationHQ"
$WORKSPACE = "$ROOT\wam-workspace"
$CONTINUE  = "$env:USERPROFILE\.continue"

function Write-Step([string]$m) { Write-Host "`n==  $m" -ForegroundColor Cyan  }
function Write-OK([string]$m)   { Write-Host "    OK   $m" -ForegroundColor Green }
function Write-Skip([string]$m) { Write-Host "    SKIP $m" -ForegroundColor DarkGray }
function Write-Warn([string]$m) { Write-Host "    WARN $m" -ForegroundColor Yellow }

# ─── STEP 0 — directories ─────────────────────────────────────────────────────
Write-Step "Step 0: Create directories"

foreach ($d in @($ROOT, $MODULES, $WORKSPACE, $CONTINUE)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
        Write-OK "Created: $d"
    } else {
        Write-Skip "Exists:  $d"
    }
}

# ─── STEP 1 — clone CloudNation modules ───────────────────────────────────────
Write-Step "Step 1: Clone CloudNation WAM modules"

# The modules most relevant to app service / web app / container workloads
# plus the core networking and security modules the AI will reference.
# Full list: https://github.com/orgs/CloudNationHQ/repositories
$repos = @(
    # Compute / app hosting
    @{ name = "terraform-azure-ca";   desc = "Container Apps — closest to App Service for containers" },
    @{ name = "terraform-azure-func"; desc = "Function Apps" },
    @{ name = "terraform-azure-vm";   desc = "Virtual Machines" },

    # Networking
    @{ name = "terraform-azure-vnet"; desc = "Virtual Network" },
    @{ name = "terraform-azure-agw";  desc = "Application Gateway" },
    @{ name = "terraform-azure-pe";   desc = "Private Endpoints" },
    @{ name = "terraform-azure-pdns"; desc = "Private DNS Zones" },
    @{ name = "terraform-azure-fd";   desc = "Front Door" },

    # Security & identity
    @{ name = "terraform-azure-kv";   desc = "Key Vault" },

    # Storage & data
    @{ name = "terraform-azure-sa";   desc = "Storage Account" },
    @{ name = "terraform-azure-sql";  desc = "SQL Database" },
    @{ name = "terraform-azure-cosmosdb"; desc = "Cosmos DB" },

    # Container infrastructure
    @{ name = "terraform-azure-acr";  desc = "Container Registry" },
    @{ name = "terraform-azure-aks";  desc = "Kubernetes Service" },

    # Observability
    @{ name = "terraform-azure-law";  desc = "Log Analytics Workspace" },
    @{ name = "terraform-azure-mds";  desc = "Diagnostic Settings" }
)

foreach ($repo in $repos) {
    $target = "$MODULES\$($repo.name)"
    if (Test-Path "$target\.git") {
        Write-Skip "$($repo.name) — already cloned, pulling latest"
        Push-Location $target
        git pull --quiet 2>$null
        Pop-Location
    } else {
        $url = "https://github.com/CloudNationHQ/$($repo.name).git"
        Write-Host "    Cloning $($repo.name) ($($repo.desc))..." -ForegroundColor Gray
        git clone $url $target --quiet 2>&1 | Out-Null
        Write-OK "$($repo.name)"
    }
}

Write-OK "All modules ready in $MODULES"

# ─── STEP 2 — build module index for the AI ───────────────────────────────────
Write-Step "Step 2: Generate module index (MODULES.md)"

# Dynamically scans ALL cloned repos — reads README.md for full description,
# features, resources deployed, and CHANGELOG.md for the actual latest version.
# Written to TWO locations simultaneously:
#   1. Runtime working copy: $ROOT\wam-workspace\MODULES.md
#   2. Repo copy:            C:\DEVOPS\ai-augmented-infra\poc\MODULES.md  (two-layer lookup)

function Get-WamModuleInfo([string]$ModulePath) {
    $info = @{ Title=''; Description=''; Features=@(); Resources=@(); Version='' }
    $readmePath = Join-Path $ModulePath "README.md"
    if (-not (Test-Path $readmePath)) { return $info }
    $raw   = [System.IO.File]::ReadAllText($readmePath, [System.Text.Encoding]::UTF8)
    $lines = $raw -split "`n"

    # Title
    $t = $lines | Where-Object { $_ -match '^#\s+\S' } | Select-Object -First 1
    if ($t) { $info.Title = ($t -replace '^#\s+','').Trim() }

    # Description
    $inDesc = $false; $descLines = @()
    foreach ($line in $lines) {
        $l = $line.Trim()
        if ($l -match '^#') { if ($inDesc) { break } else { $inDesc = $true; continue } }
        if ($inDesc -and $l -ne '' -and $l -notmatch '^<!--') { $descLines += $l }
        elseif ($inDesc -and $descLines.Count -gt 0 -and $l -eq '') { break }
    }
    $info.Description = ($descLines -join ' ').Trim()

    # Features
    if ($raw -match '(?s)## Features\s*(.*?)(?=\r?\n##|\z)') {
        $featBlock = $matches[1]
        $info.Features = ($featBlock -split "`n") |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' -and $_ -notmatch '^<!--' -and $_ -notmatch '<a name' } |
            Select-Object -First 20
    }

    # Resources
    $resMatches = [regex]::Matches($raw, '\[azurerm_([a-z_]+)\]')
    $info.Resources = $resMatches | ForEach-Object { 'azurerm_' + $_.Groups[1].Value } |
        Select-Object -Unique | Select-Object -First 20

    # Version from CHANGELOG
    $clPath = Join-Path $ModulePath "CHANGELOG.md"
    if (Test-Path $clPath) {
        $cl = Get-Content $clPath -TotalCount 20 -ErrorAction SilentlyContinue
        $vl = $cl | Where-Object { $_ -match '##\s+\[?v?\d+\.\d+' } | Select-Object -First 1
        if ($vl -match '(\d+\.\d+[\.\d]*)') { $info.Version = $matches[1] }
    }
    return $info
}

$clonedModules = Get-ChildItem $MODULES -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'terraform-azure-*' } | Sort-Object Name

$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine('# CloudNation WAM Module Index')
$null = $sb.AppendLine('')
$null = $sb.AppendLine("> Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
$null = $sb.AppendLine("> Source: $MODULES")
$null = $sb.AppendLine('> This index is read by the AI assistant to discover available CloudNation WAM modules.')
$null = $sb.AppendLine('> Always read the actual variables.tf of any module before generating its input block.')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('---')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('## Quick Reference Table')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| Module | Registry Source | Version | Purpose |')
$null = $sb.AppendLine('|---|---|---|---|')

$cache = @{}
foreach ($mod in $clonedModules) {
    $short = $mod.Name -replace '^terraform-azure-',''
    $info  = Get-WamModuleInfo $mod.FullName
    $cache[$mod.Name] = $info
    $major = if ($info.Version -match '^(\d+)\.(\d+)') { "$($matches[1]).$($matches[2])" } else { '4.0' }
    $ver   = "~> $major"
    $desc  = if ($info.Description) { $info.Description } else { "Azure $($short.ToUpper()) module" }
    $null = $sb.AppendLine("| ``$($mod.Name)`` | ``CloudNationHQ/$short/azure`` | ``$ver`` | $desc |")
}

$null = $sb.AppendLine('')
$null = $sb.AppendLine('---')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('## Detailed Module Reference')
$null = $sb.AppendLine('')

foreach ($mod in $clonedModules) {
    $short = $mod.Name -replace '^terraform-azure-',''
    $info  = $cache[$mod.Name]
    $major = if ($info.Version -match '^(\d+)\.(\d+)') { "$($matches[1]).$($matches[2])" } else { '4.0' }
    $ver   = "~> $major"

    $null = $sb.AppendLine("### $($mod.Name)")
    $null = $sb.AppendLine('')
    $null = $sb.AppendLine("- Registry source: ``CloudNationHQ/$short/azure``")
    $null = $sb.AppendLine("- Version constraint: ``$ver``")
    $null = $sb.AppendLine("- Variables schema: ``$MODULES\$($mod.Name)\variables.tf``")
    $null = $sb.AppendLine('')
    if ($info.Description) {
        $null = $sb.AppendLine($info.Description)
        $null = $sb.AppendLine('')
    }
    if ($info.Features.Count -gt 0) {
        $null = $sb.AppendLine('Key features:')
        foreach ($feat in $info.Features) {
            if ($feat -ne '') { $null = $sb.AppendLine("- $feat") }
        }
        $null = $sb.AppendLine('')
    }
    if ($info.Resources.Count -gt 0) {
        $null = $sb.AppendLine('Azure resources deployed: ' + ($info.Resources -join ', '))
        $null = $sb.AppendLine('')
    }
    $null = $sb.AppendLine('---')
    $null = $sb.AppendLine('')
}

$null = $sb.AppendLine('## App Service Equivalent Guidance')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('| Scenario | Module | Registry Source | Notes |')
$null = $sb.AppendLine('|---|---|---|---|')
$null = $sb.AppendLine('| Containerised web app (recommended) | terraform-azure-ca | ``CloudNationHQ/ca/azure`` | Includes Container App Environment |')
$null = $sb.AppendLine('| Traditional App Service (Linux/Windows) | terraform-azure-app | ``CloudNationHQ/app/azure`` | App Service plan and web app |')
$null = $sb.AppendLine('| Serverless / event-driven | terraform-azure-func | ``CloudNationHQ/func/azure`` | Azure Function Apps |')
$null = $sb.AppendLine('| VM-based web server | terraform-azure-vm | ``CloudNationHQ/vm/azure`` | IaaS approach |')
$null = $sb.AppendLine('| AKS-hosted web app | terraform-azure-aks | ``CloudNationHQ/aks/azure`` | Kubernetes-based workloads |')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('## Usage Pattern')
$null = $sb.AppendLine('')
$null = $sb.AppendLine('```hcl')
$null = $sb.AppendLine('module "example" {')
$null = $sb.AppendLine('  source  = "CloudNationHQ/<short-name>/azure"')
$null = $sb.AppendLine('  version = "~> 4.0"')
$null = $sb.AppendLine('')
$null = $sb.AppendLine("  # Always read variables.tf before generating inputs:")
$null = $sb.AppendLine("  # $MODULES\<module-name>\variables.tf")
$null = $sb.AppendLine('}')
$null = $sb.AppendLine('```')

$indexContent = $sb.ToString()

# Write runtime copy
$runtimePath = "$ROOT\wam-workspace\MODULES.md"
if (-not (Test-Path "$ROOT\wam-workspace")) {
    New-Item -ItemType Directory -Force -Path "$ROOT\wam-workspace" | Out-Null
}
[System.IO.File]::WriteAllText($runtimePath, $indexContent, [System.Text.Encoding]::UTF8)
Write-OK "Written: $runtimePath ($($clonedModules.Count) modules, $([math]::Round([System.Text.Encoding]::UTF8.GetByteCount($indexContent)/1KB,1)) KB)"

# Write repo poc copy
$repoPath = "C:\DEVOPS\ai-augmented-infra\poc\MODULES.md"
if (Test-Path "C:\DEVOPS\ai-augmented-infra\poc") {
    [System.IO.File]::WriteAllText($repoPath, $indexContent, [System.Text.Encoding]::UTF8)
    Write-OK "Written: $repoPath"
} else {
    Write-Warn "Repo poc folder not found at C:\DEVOPS\ai-augmented-infra\poc — skipping"
}

Write-Step "Step 3: Write .continuerules (workspace AI behaviour)"

# .continuerules is automatically picked up by Continue for any workspace
# that contains it. It acts as a system prompt injected into every request.
@'
You are a CloudNation platform engineer assistant. Your job is to respond to
infrastructure requests by generating complete, correct Terraform configurations
using CloudNation WAM modules.

## Rules

1. ALWAYS use CloudNation WAM modules as the source for every Azure resource.
   Never write raw azurerm_ resource blocks if a CloudNation module exists.

2. Module sources MUST use the public registry format:
   source = "CloudNationHQ/<short-name>/azure"
   For example:
     source = "git::https://github.com/CloudNationHQ/terraform-azure-ca.git"   # Container Apps
     source = "git::https://github.com/CloudNationHQ/terraform-azure-kv.git"   # Key Vault
     source = "git::https://github.com/CloudNationHQ/terraform-azure-vnet.git" # Virtual Network

3. Always pin versions with a pessimistic constraint:
   version = "~> 4.0"

4. Variable schemas MUST match the module's actual variables.tf.
   Use @folder to read the local clone before generating inputs.

5. Always include these files in every generated solution:
   - main.tf      (module calls)
   - variables.tf (input variables with types and defaults)
   - outputs.tf   (relevant outputs)
   - providers.tf (azurerm provider block, version ~> 4.0)

6. Always apply these secure defaults:
   - network rules: default_action = "Deny"
   - TLS: min_tls_version = "TLS1_2"
   - RBAC: enable_rbac_authorization = true (where applicable)
   - public network access: disabled unless explicitly requested

7. Naming convention: {type}-{workload}-{environment}
   Examples: ca-helloworld-dev, kv-helloworld-dev, vnet-helloworld-dev

8. Always include a resource group module call at the top of main.tf.

9. For "app service" or "web app" requests: use terraform-azure-ca (Container Apps).
   Always explain this mapping to the user.

10. After generating Terraform, always tell the user:
    - Which local module clone to reference for the full variable schema
    - The path: C:\DEVOPS\CloudNation\CloudNationHQ\<module-name>\variables.tf

## Module index

See MODULES.md in this workspace for the full list of available modules.
Use @file MODULES.md to load it as context before answering infrastructure questions.
'@ | Out-File -FilePath "$WORKSPACE\.continuerules" -Encoding UTF8 -Force

Write-OK "Written: $WORKSPACE\.continuerules"

# ─── STEP 4 — example prompt file ────────────────────────────────────────────
Write-Step "Step 4: Write example prompts"

@'
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
'@ | Out-File -FilePath "$WORKSPACE\PROMPTS.md" -Encoding UTF8 -Force

Write-OK "Written: $WORKSPACE\PROMPTS.md"

# ─── STEP 5 — sample generated output ────────────────────────────────────────
Write-Step "Step 5: Write sample Terraform output (helloworld-app)"

$sampleDir = "$WORKSPACE\helloworld-app"
New-Item -ItemType Directory -Force -Path $sampleDir | Out-Null

# providers.tf
@'
terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
'@ | Out-File -FilePath "$sampleDir\providers.tf" -Encoding UTF8 -Force

# variables.tf
@'
variable "workload" {
  description = "Workload name — used in resource naming"
  type        = string
  default     = "helloworld"
}

variable "environment" {
  description = "Environment name — dev, tst, prd"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Resource group for all resources"
  type        = string
  default     = "rg-helloworld-dev"
}

variable "container_image" {
  description = "Container image to deploy — replace with your app image"
  type        = string
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}
'@ | Out-File -FilePath "$sampleDir\variables.tf" -Encoding UTF8 -Force

# main.tf — uses CloudNation WAM modules from the public registry
@'
# ── Resource Group ─────────────────────────────────────────────────────────────
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# ── Log Analytics Workspace ────────────────────────────────────────────────────
# Required by Container Apps environment for observability
module "law" {
  source  = "git::https://github.com/CloudNationHQ/terraform-azure-law.git"
  version = "~> 2.0"

  workspace = {
    name                = "law-${var.workload}-${var.environment}"
    resource_group_name = azurerm_resource_group.rg.name
    location            = var.location
    retention_in_days   = 30
  }

  depends_on = [azurerm_resource_group.rg]
}

# ── Container App (App Service equivalent) ─────────────────────────────────────
# terraform-azure-ca is the CloudNation WAM module for Azure Container Apps.
# This is the recommended equivalent of Azure App Service for container workloads.
# Local clone: C:\DEVOPS\CloudNation\CloudNationHQ\terraform-azure-ca\variables.tf
module "webapp" {
  source  = "git::https://github.com/CloudNationHQ/terraform-azure-ca.git"
  version = "~> 2.0"

  container_app = {
    name                         = "ca-${var.workload}-${var.environment}"
    resource_group_name          = azurerm_resource_group.rg.name
    location                     = var.location
    container_app_environment_id = module.law.environment_id

    template = {
      containers = {
        app = {
          name   = var.workload
          image  = var.container_image
          cpu    = 0.25
          memory = "0.5Gi"
          env = {
            ENVIRONMENT = {
              value = var.environment
            }
          }
        }
      }
      min_replicas = 1
      max_replicas = 3
    }

    ingress = {
      external_enabled = true
      target_port      = 80
      traffic_weight = {
        latest_revision = true
        percentage      = 100
      }
    }
  }

  depends_on = [module.law]
}
'@ | Out-File -FilePath "$sampleDir\main.tf" -Encoding UTF8 -Force

# outputs.tf
@'
output "app_url" {
  description = "Public URL of the Hello World Container App"
  value       = module.webapp.container_app.latest_revision_fqdn
}

output "resource_group_name" {
  description = "Resource group containing all resources"
  value       = azurerm_resource_group.rg.name
}
'@ | Out-File -FilePath "$sampleDir\outputs.tf" -Encoding UTF8 -Force

Write-OK "Written: $sampleDir\*.tf"

# ─── STEP 6 — Continue config ─────────────────────────────────────────────────
Write-Step "Step 6: Write Continue config.yaml"

$configPath = "$CONTINUE\config.yaml"
if (Test-Path $configPath) {
    $bak = "$CONTINUE\config.yaml.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $configPath $bak
    Write-OK "Backed up existing config to: $bak"
}

$continueYaml = "name: CloudNation WAM PoC`nversion: 1.0.0`nschema: v1`n`nmodels:`n  - name: Qwen 2.5 Coder 14b`n    provider: ollama`n    model: qwen2.5-coder:14b`n    apiBase: http://localhost:11434`n    roles:`n      - chat`n      - edit`n      - apply`n    defaultCompletionOptions:`n      contextLength: 8192`n      temperature: 0.1`n`n  - name: Qwen 2.5 Coder 1.5b (Autocomplete)`n    provider: ollama`n    model: qwen2.5-coder:1.5b-base`n    apiBase: http://localhost:11434`n    roles:`n      - autocomplete`n    autocompleteOptions:`n      debounceDelay: 350`n      maxPromptTokens: 2048`n`nembeddingsProvider:`n  provider: ollama`n  model: nomic-embed-text`n  apiBase: http://localhost:11434`n`ncontextProviders:`n  - name: codebase`n    params:`n      nRetrievalResults: 15`n      nFinal: 8`n  - name: folder`n    params: {}`n  - name: file`n    params: {}`n  - name: code`n    params: {}`n`nindexing:`n  dirs:`n    - C:\DEVOPS\CloudNation\CloudNationHQ`n`nmcpServers:`n  - name: CloudNation Modules`n    type: stdio`n    command: npx`n    args:`n      - -y`n      - '@modelcontextprotocol/server-filesystem'`n      - 'C:\\DEVOPS\\CloudNation\\CloudNationHQ'`n`nrules:`n  - 'You are a CloudNation platform engineer preparing terraform code.'`n  - 'CRITICAL: You MUST use CloudNation WAM module blocks for every Azure resource. Writing raw resource blocks (resource azurerm_* ...) is STRICTLY FORBIDDEN when a CloudNation module exists for that resource type. This is a non-negotiable rule. Always write: module name { source = git::https://github.com/CloudNationHQ/terraform-azure-<n>.git ... } -- never resource azurerm_* { ... }'`n  - 'CRITICAL: Before writing any resource block, check MODULES.md or the cloned repos to confirm whether a CloudNation module exists for that resource type. If a module exists, you MUST use it. Raw azurerm_ resource blocks are only permitted for resource types where NO CloudNation module exists, and you must explicitly state this in a comment.'`n  - 'CRITICAL: If you find yourself writing resource azurerm_container_app, resource azurerm_key_vault, resource azurerm_storage_account, resource azurerm_virtual_network, resource azurerm_subnet, resource azurerm_log_analytics_workspace or any other resource type that has a CloudNation module -- STOP. Delete it. Replace it with the correct module block from MODULES.md.'`n  - 'Before answering any infrastructure request: first check if C:\\DEVOPS\\ai-augmented-infra\\poc\\MODULES.md exists and read it for the list of available modules. If it does not exist, fall back to using @codebase to search C:/DEVOPS/CloudNation/CloudNationHQ for relevant modules dynamically.'`n  - 'Regardless of which discovery method was used, always read the actual variables.tf of any module you intend to use before generating its input block.'`n  - 'Always generate Terraform using CloudNation WAM module blocks. Module source format: source = git::https://github.com/CloudNationHQ/terraform-azure-<n>.git -- always use the full GitHub git:: URL, never the short registry format'`n  - 'Every module block must include a version constraint using pessimistic operator: version = ''~> 4.0''. Never omit the version.'`n  - 'For app service or web app requests, use the Container Apps module: source = git::https://github.com/CloudNationHQ/terraform-azure-ca.git'`n  - 'Never invent module input argument names. Only use argument names that exist in the modules variables.tf. If unsure, state which arguments you could not verify.'`n  - 'If a required module is not found in MODULES.md or the cloned repos, say so explicitly -- do NOT silently fall back to a raw azurerm_ resource block.'`n  - 'Always include providers.tf, variables.tf and outputs.tf plus one .tf file per resource type.'`n  - 'Every .tf file must start with a comment block explaining its purpose, the resource type it contains, and its dependencies.'`n  - 'Write all files to folder C:\\DEVOPS\\CloudNation\\wam-workspace\\generated\\'`n  - 'Use variable references throughout, never hardcode values.'`n  - 'Every variable in variables.tf must have a description, a type, and a default value. Never declare a variable without all three.'`n  - 'Never use type = string for variables that have a fixed set of valid values -- use validation blocks with allowed values instead.'`n  - 'outputs.tf must export at minimum: the resource group name, and the primary endpoint or identifier of every deployed resource.'`n  - 'Never output sensitive values without marking them sensitive = true in outputs.tf.'`n  - 'Naming convention: {type}-{workload}-{environment} e.g. ca-helloworld-dev'`n  - 'If no Azure Region is mentioned, default to westeurope'`n  - 'If no environment is mentioned, default to dev'`n  - 'Every resource and module block must include a tags argument passing at minimum: environment, workload, and managed-by = terraform.'`n  - 'Always apply secure defaults: network deny-by-default, TLS 1.2 minimum, RBAC enabled.'`n  - 'Always use depends_on explicitly when a resource depends on another that Terraform cannot infer automatically.'`n  - 'Never use count or for_each based on external data sources that may change between runs. Prefer static maps defined in variables.tf.'`n  - 'Always include all dependency resources that primary resources require to function. For example: a resource group for every deployment, a virtual network and subnet before any networked resource, a network security group when deploying subnets, a Log Analytics workspace before Container Apps or AKS, a container app environment before a container app. Never assume these exist -- always declare them explicitly in a dedicated .tf file named after the resource type.'`n  - 'Decide which Azure resource types are needed to make this work end to end.'`n  - 'Local module clones are at: C:/DEVOPS/CloudNation/CloudNationHQ/<module-name>/'`n  - 'When a secret must be stored in Key Vault once and never overwritten by Terraform, use a null_resource with a local-exec provisioner that calls az keyvault secret show first and only runs az keyvault secret set if the secret does not already exist. Never use azurerm_key_vault_secret for create-once secrets as Terraform will overwrite the value on every apply.'`n  - 'After writing all files show a summary table: File | Resource type | Module source | Why it was included'"

WriteAllText($configPath, $continueYaml, [System.Text.Encoding]::UTF8)
Write-OK "Written: $configPath (22 rules)"

Write-Step "Step 7: Write VS Code workspace file"

@"
{
  "folders": [
    {
      "name": "WAM Workspace",
      "path": "$($WORKSPACE.Replace('\','\\'))"
    },
    {
      "name": "CloudNation Modules",
      "path": "$($MODULES.Replace('\','\\'))"
    }
  ],
  "settings": {
    "editor.formatOnSave": true,
    "files.associations": {
      "*.tf": "terraform",
      "*.bicep": "bicep"
    },
    "continue.enableTabAutocomplete": true,
    "terraform.languageServer.enable": true
  },
  "extensions": {
    "recommendations": [
      "Continue.continue",
      "hashicorp.terraform",
      "ms-azuretools.vscode-azureterraform",
      "ms-azuretools.vscode-bicep"
    ]
  }
}
"@ | Out-File -FilePath "$ROOT\cloudnation-wam.code-workspace" -Encoding UTF8 -Force

Write-OK "Written: $ROOT\cloudnation-wam.code-workspace"

# ─── STEP 8 — VS Code extensions ─────────────────────────────────────────────
Write-Step "Step 8: Install VS Code extensions"

if (Get-Command code -ErrorAction SilentlyContinue) {
    $exts = @(
        "Continue.continue",
        "ms-azuretools.vscode-azureterraform",
        "hashicorp.terraform",
        "ms-azuretools.vscode-bicep",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "ms-azuretools.vscode-docker"
    )
    foreach ($e in $exts) {
        code --install-extension $e --force 2>&1 | Out-Null
        Write-OK $e
    }
} else {
    Write-Warn "VS Code 'code' command not found in PATH — skipping extensions"
}

# ─── DONE ─────────────────────────────────────────────────────────────────────
Write-Host @"

  ╔══════════════════════════════════════════════════════════════════╗
  ║   Setup complete — CloudNation WAM + Continue context ready     ║
  ╠══════════════════════════════════════════════════════════════════╣
  ║                                                                 ║
  ║   1. Open the workspace in VS Code:                             ║
  ║      code C:\DEVOPS\CloudNation\cloudnation-wam.code-workspace  ║
  ║                                                                 ║
  ║   2. Open the Continue panel (left sidebar)                     ║
  ║      Verify both models show green connection indicators        ║
  ║                                                                 ║
  ║   3. Try this prompt in Continue:                               ║
  ║                                                                 ║
  ║      @file MODULES.md                                           ║
  ║      Create an app service showing hello world                  ║
  ║                                                                 ║
  ║   4. For a specific module deep-dive:                           ║
  ║      @folder C:\DEVOPS\CloudNation\CloudNationHQ\terraform-azure-ca
  ║      Show me how to deploy a container app                      ║
  ║                                                                 ║
  ║   5. See PROMPTS.md for more example prompts:                   ║
  ║      C:\DEVOPS\CloudNation\PROMPTS.md             ║
  ║                                                                 ║
  ║   6. See a sample generated output:                             ║
  ║      C:\DEVOPS\CloudNation\helloworld-app\        ║
  ║                                                                 ║
  ╚══════════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan