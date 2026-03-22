# Part 1: Architecture & WAM Conceptualization

---

## 1. Module Typology

CloudNation's Well-Architected Modules (WAM) are organized into two distinct layers: **Resource Modules** and **Pattern Modules**. This separation is deliberate — it balances technical reusability with architectural governance, allowing teams at different abstraction levels to consume infrastructure in the way that suits them best.

### Resource Modules (Low-Level Building Blocks)

Resource Modules are single-purpose, low-level Terraform modules that encapsulate exactly one Azure resource type. Each module exposes a clean, validated interface over the underlying Terraform provider resource, applying secure defaults while still allowing full configuration flexibility.

A practical example is [`terraform-azure-sa`](https://github.com/CloudNationHQ/terraform-azure-sa), which manages an Azure Storage Account and all its directly related sub-resources: blob containers, file shares, queues, tables, ADLS Gen2 file systems, management lifecycle policies, and local users. Similarly, [`terraform-azure-kv`](https://github.com/CloudNationHQ/terraform-azure-kv) manages an Azure Key Vault and its associated keys, secrets, and certificates — including support for key rotation policies and certificate issuers — all within a single, cohesive module boundary.

These modules are:

- **Highly composable** — they are designed to be called by Pattern Modules or directly by platform engineers who need fine-grained control.
- **Strictly typed** — both `terraform-azure-sa` and `terraform-azure-kv` use deeply nested `object()` variable types with explicit `optional()` defaults, meaning only valid, well-formed configurations can be passed in.
- **Secure by default** — sensible security defaults are baked in out of the box, though they remain overridable for advanced use cases.

> Think of Resource Modules as the individual Lego bricks in a set — standardized, interchangeable, and well-defined.

---

### Pattern Modules (High-Level Architectures)

Pattern Modules are high-level, opinionated compositions that wire together multiple Resource Modules to deliver a complete, production-ready architectural pattern. They embed CloudNation's accumulated knowledge of security baselines, naming conventions, and compliance requirements directly into the infrastructure definition.

A Pattern Module for a "Secure Data Landing Zone," for example, would internally call `terraform-azure-sa` (for ADLS Gen2-enabled storage), `terraform-azure-kv` (for customer-managed encryption keys), and potentially networking and monitoring modules — orchestrating the interactions between them according to CloudNation's Well-Architected standards. The consuming developer provides only high-level intent (e.g., workload name, environment, data classification); all the architectural decisions are already made.

> Think of Pattern Modules as pre-assembled Lego sets — the individual bricks are still there, but the creative and structural work has already been done.

---

### Key Architectural Difference

| Dimension | Resource Module | Pattern Module |
|---|---|---|
| Abstraction level | Single Azure resource | Multi-resource architectural pattern |
| Target audience | Platform engineers | Application teams / developers |
| Configuration scope | Full resource configurability | Opinionated, limited surface area |
| Example | `terraform-azure-kv` | Secure Data Landing Zone |
| Composition | Wraps one Terraform resource | Orchestrates multiple Resource Modules |

The critical distinction is one of **scope and intent**. Resource Modules answer the question *"How do I correctly configure this Azure resource?"* Pattern Modules answer *"How do I correctly build this architectural pattern on Azure?"*

---

## 2. Why Resource Modules Are Open Source and Pattern Modules Are Private

The decision to open-source Resource Modules while keeping Pattern Modules private is a strategic one, grounded in both commercial and technical reasoning.

**Resource Modules are open source because** their content reflects established industry standards rather than proprietary knowledge. The `terraform-azure-sa` module, for instance, wraps the `azurerm_storage_account` Terraform resource — a publicly documented Azure capability. The value CloudNation adds here is in the quality of the defaults, the depth of validation, and the breadth of supported sub-resources. Making this layer public allows CloudNation to build community trust, drive adoption of their standards, attract contributions, and establish `terraform-azure-sa` and `terraform-azure-kv` as reference implementations on the Terraform Registry. There is minimal intellectual property risk: a competitor seeing these modules learns nothing about how CloudNation deploys real enterprise workloads.

**Pattern Modules are private because** they contain CloudNation's actual architectural decisions — the *how* of building complex, compliant cloud environments for enterprise and ISV clients. A Pattern Module encodes which Resource Modules to use together, how they are wired, what naming conventions to apply, which regulatory controls to enforce, and how to handle environment-specific variations. This is precisely the institutional knowledge that constitutes CloudNation's competitive advantage. Exposing it publicly would effectively hand competitors — and clients attempting to self-serve — the entire delivery methodology CloudNation has built over years of engagements.

In short: open-sourcing Resource Modules builds credibility and community; keeping Pattern Modules private protects the business.

---

## 3. The Well-Architected Bridge

The Azure Well-Architected Framework (WAF) defines five pillars — **Security**, **Reliability**, **Performance Efficiency**, **Cost Optimization**, and **Operational Excellence** — as theoretical principles. WAM modules translate these principles into concrete, enforceable Terraform code. The following examples draw directly from `terraform-azure-kv` and `terraform-azure-sa` to illustrate how this bridge operates in practice.

---

### Example A: `terraform-azure-kv` — Security & Reliability Pillars

The Key Vault module encodes multiple WAF pillars through its variable defaults and internal resource configuration.

**Security pillar — network isolation and access control:**

The `vault` input object defaults `enable_rbac_authorization` to `true`, meaning every Key Vault provisioned through this module uses Azure RBAC rather than legacy vault access policies for authorization. The `network_acls` block defaults `default_action` to `"Deny"` and `bypass` to `"AzureServices"`, ensuring the vault is not publicly reachable unless an explicit IP rule or VNet subnet is added:

```hcl
module "keyvault" {
  source = "CloudNationHQ/kv/azure"

  vault = {
    name                      = "kv-workload-prod"
    enable_rbac_authorization = true  # default: true — enforces RBAC over access policies

    network_acls = {
      default_action = "Deny"          # default: "Deny" — no public access by default
      bypass         = "AzureServices" # default: "AzureServices"
      ip_rules       = []              # explicit allow-listing required
    }
  }
}
```

This means a developer cannot accidentally deploy a publicly accessible Key Vault by omitting the `network_acls` block — the secure configuration is the default.

**Reliability pillar — data protection:**

The module defaults `purge_protection_enabled` to `true` and `soft_delete_retention_days` to `90`. Purge protection prevents any principal — including vault administrators — from permanently destroying secrets or keys before the retention period expires. This directly implements the WAF Reliability guidance on protecting against accidental or malicious data loss:

```hcl
vault = {
  name                       = "kv-workload-prod"
  purge_protection_enabled   = true  # default: true — prevents permanent deletion
  soft_delete_retention_days = 90    # default: 90 days — maximum recovery window
}
```

A workload team consuming this module cannot disable these protections without explicitly overriding them and documenting why — the safe path is the default path.

**Security pillar — automated key lifecycle management:**

The module supports key rotation policies, allowing cryptographic keys to be rotated automatically before expiry:

```hcl
vault = {
  name = "kv-workload-prod"
  keys = {
    cmk = {
      key_type = "RSA"
      key_size = 4096
      key_opts = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
      rotation_policy = {
        expire_after         = "P18M"  # key expires after 18 months
        notify_before_expiry = "P30D"  # notify 30 days before
        automatic = {
          time_before_expiry = "P14D"  # auto-rotate 14 days before expiry
        }
      }
    }
  }
}
```

This enforces the WAF Security pillar guidance on cryptographic key hygiene without requiring developers to manually track and rotate keys.

---

### Example B: `terraform-azure-sa` — Security, Reliability, and Operational Excellence Pillars

**Security pillar — transport and access control:**

The `storage` input object defaults `https_traffic_only_enabled` to `true` and `min_tls_version` to `"TLS1_2"`, ensuring all data in transit is encrypted with a modern protocol. The `allow_nested_items_to_be_public` default of `false` prevents any blob container from being inadvertently exposed to the public internet, regardless of what the consuming team configures at the container level:

```hcl
module "storage" {
  source = "CloudNationHQ/sa/azure"

  storage = {
    name                            = "stworkloadprod"
    account_replication_type        = "GRS"   # default: "GRS" — geo-redundant
    https_traffic_only_enabled      = true    # default: true — enforces HTTPS
    min_tls_version                 = "TLS1_2" # default: "TLS1_2"
    allow_nested_items_to_be_public = false   # default: false — blocks public blobs

    network_rules = {
      default_action = "Deny"    # lock down by default
      bypass         = ["None"]  # no bypass for trusted services unless explicitly added
    }
  }
}
```

**Reliability pillar — geo-redundancy and soft delete:**

The module defaults `account_replication_type` to `"GRS"` (Geo-Redundant Storage), ensuring data is replicated to a secondary Azure region automatically. The `blob_properties` block supports `delete_retention_policy`, `container_delete_retention_policy`, and `restore_policy`, enabling point-in-time recovery:

```hcl
storage = {
  name                     = "stworkloadprod"
  account_replication_type = "GRS"  # default: geo-redundant

  blob_properties = {
    versioning_enabled = true
    delete_retention_policy = {
      days = 14  # blobs recoverable for 14 days after deletion
    }
    container_delete_retention_policy = {
      days = 14
    }
    restore_policy = {
      days = 7  # point-in-time restore window
    }
  }
}
```

**Security pillar — immutability for compliance workloads:**

The module supports container-level immutability policies, which satisfy regulatory requirements for data that must not be altered or deleted for a defined period — a common requirement in financial services and healthcare:

```hcl
storage = {
  name = "stworkloadprod"
  blob_properties = {
    containers = {
      audit-logs = {
        immutability_policy = {
          immutability_period_in_days     = 365  # WORM: 1 year retention
          protected_append_writes_enabled = true  # allow appends, not overwrites
          locked                          = true  # policy cannot be shortened once locked
        }
      }
    }
  }
}
```

**Operational Excellence pillar — lifecycle management:**

The module's `management_policy` block allows teams to define automated tiering and deletion rules, translating WAF Cost Optimization and Operational Excellence guidance into policy-as-code:

```hcl
storage = {
  name = "stworkloadprod"
  management_policy = {
    rules = {
      archive-old-blobs = {
        enabled = true
        filters = {
          blob_types   = ["blockBlob"]
          prefix_match = ["data/"]
        }
        actions = {
          base_blob = {
            tier_to_cool_after_days_since_modification_greater_than    = 30
            tier_to_archive_after_days_since_modification_greater_than = 90
            delete_after_days_since_modification_greater_than          = 365
          }
        }
      }
    }
  }
}
```

---

### Summary: How WAM Modules Enforce WAF Pillars

| WAF Pillar | `terraform-azure-kv` enforcement | `terraform-azure-sa` enforcement |
|---|---|---|
| **Security** | RBAC default on, `network_acls` deny-by-default, purge protection, key rotation | HTTPS-only, TLS 1.2 minimum, no public blobs, network deny-by-default |
| **Reliability** | Soft delete (90 days), purge protection, geo-aware deployment | GRS replication default, blob versioning, point-in-time restore, soft delete |
| **Operational Excellence** | Key rotation policies, certificate lifecycle management | Lifecycle management policies, automated tiering, consistent tagging |
| **Cost Optimization** | Right-sized SKU selection | Automated blob tiering (Hot → Cool → Archive → Delete) |

The WAM model's insight is that the Well-Architected Framework's pillars are not merely documentation guidance — they are design constraints that belong in code. By encoding secure and reliable defaults directly into Resource Modules, CloudNation ensures that compliance is the path of least resistance for every team consuming their modules, regardless of that team's cloud maturity.

---

> **Conclusion:** Resource Modules like `terraform-azure-kv` and `terraform-azure-sa` serve as the codified translation layer between the theoretical principles of the Azure Well-Architected Framework and the concrete infrastructure that runs in production. Pattern Modules then compose these building blocks into complete, governed architectures — turning organizational standards into repeatable, auditable deployments at scale.
