# Part 2: AI Agent & MCP Integration Design

---

## Preface: Understanding the MCP Architectural Vocabulary

Before designing a system built on the Model Context Protocol, it is essential to draw clear distinctions between three terms that are frequently conflated: the **protocol**, the **host**, and the **server**. Conflating them leads to architectures that misplace responsibilities and create security or governance gaps.

### The Protocol

MCP is, first and foremost, a **communication standard** — not a piece of software. Released by Anthropic in November 2024 and now stewarded under the Linux Foundation's Agentic AI Foundation, it defines a JSON-RPC 2.0-based message format through which AI models can discover and invoke external **Resources** (read-only data), **Tools** (executable functions), and **Prompts** (reusable instruction templates). The protocol specifies capability negotiation, session lifecycle, transport mechanisms (stdio for local processes, Server-Sent Events / HTTP for remote services), and error codes. It does not execute anything — it is the language that components use to talk to each other.

### The MCP Host

The **host** is the process that contains the AI model and acts as the security broker and orchestrator for the entire session. In the CloudNation developer context, this would be Cursor, Windsurf, or a custom CLI agent tool. The host is responsible for creating and managing one or more **MCP clients**, enforcing which servers those clients may connect to, handling user consent and authorization decisions, aggregating context from multiple servers, and coordinating the LLM's sampling (inference) calls. Critically, **the host controls what the AI is allowed to see and do** — servers cannot access the full conversation history or observe each other's outputs. Each server connection is isolated within its own client.

### The MCP Client

Each **client** is a protocol-layer component embedded within the host. It maintains a dedicated, stateful, 1:1 session with a single MCP server, handling protocol negotiation and bidirectional message routing. A single host can manage multiple clients simultaneously — for example, one client connected to the CloudNation WAM MCP server, another to a Git MCP server, and a third to a CI/CD pipeline server.

### The MCP Server

The **server** is the component that exposes capabilities to the AI. It operates independently, knows nothing about the broader conversation, and responds only to MCP-formatted requests routed through its paired client. In the CloudNation architecture, the WAM MCP server is a purpose-built service that exposes Terraform module metadata, naming conventions, security standards, and controlled tool invocations as MCP primitives. It is the boundary between the AI and CloudNation's proprietary systems.

The distinction that matters most architecturally: **the protocol defines the contract; the host enforces policy; the server exposes capability.** A well-designed system places governance logic in the host and business logic in the server, keeping them cleanly separated.

```
┌──────────────────────────────────────────────────────────┐
│                    MCP HOST                              │
│  (Cursor / Windsurf / Custom CLI Agent)                  │
│                                                          │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐            │
│   │MCP Client│   │MCP Client│   │MCP Client│            │
│   │    A     │   │    B     │   │    C     │            │
│   └────┬─────┘   └────┬─────┘   └────┬─────┘            │
│        │              │              │                   │
│    JSON-RPC 2.0 over stdio / SSE / HTTP                  │
└────────┼──────────────┼──────────────┼───────────────────┘
         │              │              │
         ▼              ▼              ▼
  ┌─────────────┐ ┌───────────┐ ┌───────────────┐
  │ CloudNation │ │  Git MCP  │ │  CI/CD MCP    │
  │  WAM MCP   │ │  Server   │ │  Server       │
  │  Server    │ │           │ │  (read-only)  │
  └─────────────┘ └───────────┘ └───────────────┘
  Resources: module   Tools:       Tools:
  metadata, naming    clone,       trigger-plan,
  conventions         read-file    get-plan-output
  Tools: validate-hcl
  Prompts: scaffolding
  templates
```

This separation is not merely conceptual — it has direct security implications. Because the host controls client lifecycle and consent, a compromised MCP server cannot escalate into the broader session or access credentials meant for a different server.

---

## 1. Developer Workflow Integration

### The Full Conceptual Workflow

The following describes the end-to-end journey from a developer's natural-language intent to production-ready infrastructure, mediated by the CloudNation MCP ecosystem.

**Phase 1 — Intent declaration.** The developer opens their AI-enabled IDE (Cursor or Windsurf) and describes the desired outcome in natural language: *"Provision a secure, production-grade data landing zone for the payments team with private networking, ADLS Gen2 storage, and customer-managed encryption keys, following CloudNation naming standards for the `prod` environment."* The host captures this intent and begins orchestrating the agent loop.

**Phase 2 — Context retrieval via MCP.** The host's MCP client sends a `resources/list` and subsequent `resources/read` request to the CloudNation WAM MCP server. The server — backed by a RAG retrieval layer over CloudNation's private repositories — returns the most relevant Pattern Module (e.g., a Secure Data Landing Zone pattern), the applicable Resource Modules it composes (including `terraform-azure-sa` and `terraform-azure-kv`), the naming convention schema for the `prod` environment, and the active security baseline. This context is injected directly into the LLM's prompt window. The AI never contacts the private Git repository directly — all access is mediated by the MCP server.

**Phase 3 — Terraform generation.** With the retrieved context grounding the generation, the AI produces a Terraform configuration that calls only approved WAM modules, applies correct naming, sets required input values, and respects the security baseline. It cannot hallucinate module names or arguments it did not receive from the MCP server.

**Phase 4 — MCP-mediated validation.** Before the code leaves the IDE, the MCP server exposes a `validate_hcl` tool. The host's client invokes this tool with the generated Terraform, and the server runs `terraform validate` and a policy check (e.g., using OPA or Checkov) against the CloudNation ruleset. The result — pass or a structured list of violations — is returned to the AI, which revises the configuration accordingly. This loop may iterate several times before producing a clean result.

**Phase 5 — Git commit and pull request.** The validated configuration is committed to a feature branch. The AI agent, through the Git MCP server, opens a pull request with a structured description of what was provisioned and why, referencing the Pattern Module used and the security standards applied. Human reviewers can inspect both the Terraform and the AI's reasoning.

**Phase 6 — CI/CD pipeline execution.** The PR triggers the CloudNation CI/CD pipeline, which runs the full validation suite: Terraform lint → `terraform validate` → unit tests (e.g., Terratest) → policy-as-code (OPA/Checkov) → `terraform plan` in a sandbox → integration tests → plan review artifact posted to the PR. No infrastructure changes occur at this stage.

**Phase 7 — Approval gate.** For non-production environments, pipeline approval may be automatic if all gates pass. For production, a mandatory human approval is required before `terraform apply` is executed. The AI has no role in this step — it submitted its output at Phase 5 and the pipeline takes full ownership from there.

```
Developer Intent
      │
      ▼
AI IDE / CLI (MCP Host)
      │
      ├─── MCP Client A ──► CloudNation WAM MCP Server
      │                       ├── Resources: Pattern Modules, Resource Modules,
      │                       │              naming conventions, security baselines
      │                       ├── Tools: validate_hcl, check_naming, list_modules
      │                       └── Prompts: scaffolding templates
      │
      ├─── MCP Client B ──► Git MCP Server
      │                       └── Tools: create_branch, open_pr, read_file
      │
      └─── MCP Client C ──► CI/CD MCP Server (read-only)
                              └── Tools: get_plan_output, get_run_status
                                  (trigger only, never execute apply)
      │
      ▼
  Generated & Validated Terraform
      │
      ▼
  Pull Request → CI/CD Pipeline
      │
      ├── Lint → Validate → Unit Tests → Policy Check → terraform plan (sandbox)
      │
      ├── Plan artifact posted to PR for human review
      │
      └── Approval gate → terraform apply (pipeline only, never AI)
```

### Key Architectural Principle

The AI agent accelerates the authoring phase. Everything from commit onward is owned by deterministic, auditable systems. The AI never touches infrastructure state.

---

## 2. Context Retrieval & Ingestion: The RAG Backend

Making the CloudNation WAM MCP server genuinely useful — rather than a source of confident hallucination — requires a carefully engineered retrieval backend. The design below is presented in two layers: a high-level architectural view, followed by a detailed low-level specification of tooling, configuration, and interactions.

### 2.1 High-Level Architecture

The retrieval system consists of four logical stages: **ingestion**, **indexing**, **retrieval**, and **injection**.

**Ingestion** is the offline process of reading CloudNation's private Git repositories, parsing Terraform files and documentation, chunking them into semantically coherent units, generating vector embeddings, and storing those embeddings in a vector database alongside structured metadata. This process is triggered by Git webhooks on every merge to the main branch of any WAM repository.

**Indexing** maintains a versioned, queryable representation of CloudNation's module library. Only modules tagged as stable or approved are indexed for production use. Draft and deprecated modules are excluded or flagged.

**Retrieval** is the online, per-request process: when an AI agent sends a query to the MCP server, the server embeds that query using the same embedding model used at ingestion time, performs an approximate nearest-neighbour search against the vector store, applies metadata filters (module type, stability tag, WAF pillar), and returns the top-ranked chunks.

**Injection** is the act of packaging retrieved chunks into the MCP `resources/read` response, which the host injects into the LLM's context window. The AI sees only what was retrieved — it cannot access modules or conventions that are not returned.

```
                      ┌─────────────────────────────────────┐
                      │         OFFLINE INGESTION           │
                      │                                     │
  Private Git Repos   │  Parser → Chunker → Embedder        │
  (WAM Pattern +      │                ↓                    │
   Resource Modules)  │       Vector Store (indexed)        │
       │              │       + Metadata Store              │
       │              └─────────────────────────────────────┘
       │                                ↑
       └── Git Webhook (merge to main) ─┘

                      ┌─────────────────────────────────────┐
                      │          ONLINE RETRIEVAL           │
                      │                                     │
  AI Agent Query ───► │  MCP Server → Embed Query           │
                      │           → ANN Search              │
                      │           → Metadata Filter         │
                      │           → Re-rank                 │
                      │           → Inject into Response    │
                      └─────────────────────────────────────┘
```

### 2.2 Low-Level Design: Tooling, Configuration, and Interactions

#### Ingestion Pipeline

**Git access and secret management.** The ingestion service authenticates to private GitHub/Azure DevOps repositories using a dedicated machine identity — a GitHub App with read-only permissions scoped to specific repositories, not a personal access token. The App's private key is stored in Azure Key Vault (provisioned via `terraform-azure-kv` with `purge_protection_enabled = true` and RBAC authorization). The ingestion service retrieves the secret at startup via the Azure SDK's `DefaultAzureCredential` chain, which resolves to a Workload Identity in a Kubernetes pod — no credentials are stored in environment variables or container images.

**Parsing.** Raw `.tf` files require structured parsing, not plain text extraction. The ingestion service uses the `python-hcl2` library to parse HCL into Python dicts, extracting module metadata — `source`, `version`, `description`, declared input variables with their types and defaults, outputs, and any inline comments — as structured JSON. Markdown documentation files (`README.md`, `GOALS.md`) are parsed with `mistune` or `markdown-it-py`. The structured JSON representation of a module is more token-efficient and retrieval-precise than raw HCL text, because it allows the system to answer queries like "what are the security-relevant inputs to `terraform-azure-kv`?" with a compact, factual response rather than a wall of raw code.

**Chunking strategy.** Modules are chunked at the **module boundary** rather than at arbitrary token counts. Each chunk represents one logical unit: a module's full variable schema, a module's output definitions, a specific sub-resource's configuration block (e.g., the `blob_properties` block of `terraform-azure-sa`), or a named example from the `examples/` directory. This is preferable to sliding-window chunking because Terraform modules have natural semantic boundaries, and a chunk that spans two unrelated modules will degrade retrieval precision. The target chunk size is 400–600 tokens. A small overlap of 50 tokens is applied only for prose documentation, not for structured HCL JSON.

Each chunk is stored with the following metadata schema:

```json
{
  "module_name": "terraform-azure-kv",
  "module_version": "4.3.0",
  "chunk_type": "variable_schema | output | example | documentation",
  "waf_pillars": ["Security", "Reliability"],
  "stability": "stable",
  "source_file": "variables.tf",
  "source_url": "https://github.com/CloudNationHQ/terraform-azure-kv/blob/v4.3.0/variables.tf",
  "last_indexed_at": "2026-03-21T10:00:00Z",
  "content_hash": "sha256:abc123..."
}
```

**Embedding model.** The embedding model must handle HCL syntax, technical terminology, and natural-language descriptions with equal facility. The recommended model is **`text-embedding-3-large`** (OpenAI, 3072 dimensions, reducible to 1536 for cost efficiency) or **`text-embedding-004`** (Google Vertex AI) if CloudNation's stack is Azure/GCP-native and a managed service is preferred. For a fully self-hosted option to avoid data egress of proprietary module code, **`BAAI/bge-m3`** deployed on a Kubernetes inference pod via KServe provides multilingual, multi-vector embedding with no external API calls. The embedding model used at ingestion time must be identical to the one used at retrieval time — this is enforced by storing the model name in the vector store's collection metadata and asserting it at server startup.

**Vector store.** The recommended vector database is **Qdrant**, deployed as a Kubernetes StatefulSet with persistent volumes, or as Qdrant Cloud for a managed option. Qdrant is chosen over Pinecone (proprietary, US-hosted, potential data residency issues for EU clients) and over FAISS (in-memory only, no metadata filtering). Qdrant supports:

- Named collections with per-collection configuration (distance metric, vector dimensions, quantization)
- Payload-based filtering (filter by `stability = "stable"` before ANN search)
- Sparse vector support for hybrid retrieval (BM25 keyword search combined with dense vector search)
- Snapshot-based backups
- Role-based access control via API keys

The Qdrant collection for WAM modules is configured as:

```yaml
collection_name: cloudnation_wam_modules
vectors:
  size: 1536          # text-embedding-3-large with dimension reduction
  distance: Cosine
optimizers_config:
  indexing_threshold: 20000   # build HNSW index after 20k vectors
hnsw_config:
  m: 16               # HNSW graph connections — higher = better recall, more memory
  ef_construct: 100   # construction-time search width
quantization_config:
  scalar:
    type: int8        # 4x memory reduction with minimal recall loss
```

**Re-indexing on change.** A GitHub Actions workflow (or Azure DevOps pipeline) fires on every merge to the `main` branch of any WAM repository. It calls the ingestion service's `/ingest` API endpoint, passing the repository name and the new commit SHA. The ingestion service fetches only the changed files (`git diff`), re-parses and re-embeds them, and upserts the new vectors using the content hash as the deduplication key. Stale vectors for deleted or renamed files are removed. This incremental approach keeps the index current without re-processing the entire corpus on every change.

#### Retrieval at Query Time

When the AI agent sends a query to the CloudNation WAM MCP server (via the MCP `resources/read` or `tools/call` mechanism), the following chain executes:

1. **Query understanding.** The MCP server receives the natural-language query or structured tool request. If the query is ambiguous (e.g., "storage module"), the server applies a lightweight classifier to determine whether the developer is asking about a Resource Module, a Pattern Module, or a security convention.

2. **Query embedding.** The query is embedded using the same model as the corpus. This is a synchronous call with a target latency under 100ms, achieved by keeping the embedding service in the same Kubernetes cluster as the MCP server.

3. **Hybrid retrieval.** The embedded query is sent to Qdrant with a combined dense + sparse (BM25) retrieval request. This hybrid approach is critical for Terraform contexts: semantic search finds conceptually related modules even if the terminology differs, while keyword search precisely matches HCL identifiers like `azurerm_storage_account` or `enable_rbac_authorization`. The payload filter applies `stability = "stable"` unconditionally, excluding draft modules from all agent-visible results.

4. **Re-ranking.** The top-20 candidate chunks from Qdrant are re-ranked using a cross-encoder model (e.g., `cross-encoder/ms-marco-MiniLM-L-6-v2`) to improve precision. The top-5 to top-8 chunks are selected for injection. Re-ranking adds approximately 50–150ms latency but meaningfully improves the relevance of the final context, reducing the risk of the AI receiving a plausible-but-wrong module definition.

5. **Response assembly and injection.** The MCP server packages the retrieved chunks into a structured `ResourceContent` response, including the chunk content, source URL, module version, and WAF pillar tags. The host injects this into the LLM's context window as grounding material.

#### Anti-Hallucination Controls

The most important anti-hallucination control is structural: **the AI cannot reference a module it was not shown**. This is enforced by the MCP server's `validate_hcl` tool, which checks every module `source` reference in the generated Terraform against an allowlist of approved module identifiers maintained in the metadata store. Any reference to a module not in the allowlist causes the validation to fail with a structured error, which the AI must resolve by either retrieving the correct module or asking the developer for clarification.

A secondary control is the **context freshness assertion**: the MCP server includes a `retrieved_at` timestamp and the latest `module_version` for each chunk. If the LLM generates code referencing a variable that does not exist in the version it was shown, `terraform validate` (invoked via the `validate_hcl` tool) will catch it. The combination of accurate context injection and automated validation creates a closed feedback loop that is far more reliable than instruction-based prompting alone.

Finally, the MCP server maintains a **negative allowlist**: a set of known-bad patterns (e.g., `public_network_access_enabled = true` without an accompanying justification, or `purge_protection_enabled = false` for Key Vault) that trigger a policy violation regardless of what the AI generates. These are enforced by the OPA policy layer in the `validate_hcl` tool, not by the LLM.

---

## 2.3 MCP Server Access Control: Authentication and Authorisation at the Entry Point

The RAG backend design in Section 2.2 addresses how module content is stored and retrieved accurately. An equally important question — one that the architecture must answer before any retrieval occurs — is: **who is allowed to query the MCP server, and what are they allowed to retrieve?**

Without an access control layer at the MCP server entry point, a developer's IDE session could query Pattern Module content it has no business accessing, or an external actor who has obtained a developer's IDE configuration could connect to the server and exfiltrate CloudNation's proprietary architectural knowledge. The MCP server is, after all, the boundary between the AI and CloudNation's private systems — and that boundary must be enforced by more than network topology alone.

### Authentication: Validating the Calling Identity

Every request arriving at the CloudNation WAM MCP server must carry a verifiable identity token. The recommended approach is **OAuth 2.0 with PKCE** (Proof Key for Code Exchange), using Azure Entra ID (formerly Azure Active Directory) as the identity provider. This is consistent with the wider CloudNation toolchain, which already uses Entra ID for developer identities, service principals, and Workload Identity in Kubernetes.

The flow is as follows:

1. When the developer's IDE (Cursor, Windsurf, or a custom CLI agent) initialises a connection to the WAM MCP server, the MCP host triggers an OAuth 2.0 authorisation code flow against the CloudNation Entra ID tenant.
2. The developer authenticates interactively (or silently via a cached token) and receives a short-lived JWT access token scoped to the MCP server's registered application.
3. Every subsequent MCP message from the host includes this token in the `Authorization: Bearer` header.
4. The MCP server validates the token on every request: signature, issuer, audience, expiry, and scope. An invalid or expired token results in an immediate `401 Unauthorized` response — the server does not process the request at all.

This means the MCP server trusts no ambient identity — not the network, not the Kubernetes namespace, not the developer's machine. Every call is authenticated independently.

### Authorisation: Scoping What Each Identity Can Access

Authentication confirms who is calling. Authorisation determines what they are allowed to retrieve. CloudNation's module library contains two tiers of content with different sensitivity levels:

- **Resource Modules** — public, open-source, no access restriction required beyond authentication
- **Pattern Modules** — proprietary, commercially sensitive, access restricted by client engagement and role

The MCP server enforces this distinction through a **claims-based authorisation model**. The Entra ID access token contains group membership claims that the MCP server maps to content permissions:

```
Token claim: groups = ["cloudnation-internal", "client-contoso-engagement"]

MCP server resolves:
  cloudnation-internal     → can query Resource Modules + all Pattern Modules
  client-contoso-engagement → can query Resource Modules + Contoso-scoped Pattern Modules only
  (no matching claim)       → can query Resource Modules only
```

This is enforced at the Qdrant query layer: before executing any vector search, the MCP server applies a **payload filter** that restricts results to collections the calling identity has permission to access. A developer on a Contoso engagement cannot retrieve Pattern Module chunks scoped to a different client — not because those chunks are in a different physical store, but because the metadata filter excludes them from the query results.

```python
# MCP server retrieval — authorisation enforced at query time
def retrieve_modules(query: str, identity: JWTClaims) -> list[Chunk]:
    permitted_collections = resolve_permitted_collections(identity.groups)

    return qdrant_client.search(
        collection_name="cloudnation_wam_modules",
        query_vector=embed(query),
        query_filter=Filter(
            must=[
                FieldCondition(
                    key="collection_scope",
                    match=MatchAny(any=permitted_collections)
                )
            ]
        ),
        limit=20
    )
```

### Practical Implications for the Developer Workflow

From the developer's perspective, the access control layer is invisible during normal use. They authenticate once per IDE session (or implicitly via cached credentials), and the MCP server silently scopes every retrieval to their permitted content. If they ask for a Pattern Module they do not have access to, the server returns an empty result set rather than an error — the AI receives no context for that module and must report that it could not find a suitable pattern, prompting the developer to request access through the normal CloudNation engagement process.

All access attempts — successful retrievals, empty results due to authorisation scope, and authentication failures — are written to the audit log alongside the session identity, timestamp, and query content. This provides a complete, tamper-evident record of who accessed what pattern knowledge and when.

---
## 3. Tool Execution vs. Generation: The Execution Boundary

### The Boundary, Precisely Defined

The central architectural decision is this: **the AI agent operates exclusively in the generation and analysis domain; all infrastructure state changes are owned by the CI/CD pipeline**. This is not merely a safety preference — it is a governance requirement.

The justification is grounded in the properties we need from infrastructure execution: it must be auditable, reproducible, gated by human approval where required, and associated with a traceable identity (a pipeline service principal with logged credentials) rather than an ephemeral agent session. AI agents, by their nature, are probabilistic and context-dependent. CI/CD pipelines are deterministic and logged. Infrastructure state changes must be deterministic.

The boundary is therefore drawn as follows:

| Capability                                   | AI Agent (via MCP)                        | CI/CD Pipeline              |
|----------------------------------------------|-------------------------------------------|-----------------------------|
| Retrieve module definitions and examples     | Yes                                       | No                          |
| Generate Terraform HCL                       | Yes                                       | No                          |
| Validate HCL syntax (`terraform validate`)   | Yes (via MCP tool)                        | Yes                         |
| Run policy checks (OPA / Checkov)            | Yes (via MCP tool)                        | Yes                         |
| Open a pull request                          | Yes (via Git MCP tool)                    | No                          |
| Execute `terraform plan`                     | No (direct); Yes (read result via MCP)    | Yes (owns execution)        |
| Execute `terraform apply`                    | Never                                     | Yes (with approval gate)    |
| Modify Terraform state                       | Never                                     | Yes                         |
| Access production credentials                | Never                                     | Yes (via OIDC, short-lived) |

### Why `terraform plan` Is Permitted in CI/CD but Not Directly by the AI

There is a meaningful difference between *running* `terraform plan` and *reading the output of* `terraform plan`. The AI agent is permitted to do the latter — the CI/CD MCP server exposes a `get_plan_output` tool that returns the structured JSON output of the most recent plan run for a given PR. This allows the agent to analyze the plan, identify unexpected resource deletions or replacements, and suggest fixes to the developer. What it cannot do is trigger a plan against production infrastructure directly, because doing so would require giving the agent access to production state backend credentials and provider authentication — a privilege that must be held only by the pipeline's OIDC-authenticated service identity.

### Why `terraform apply` Must Never Be AI-Executable

Direct AI execution of `terraform apply` introduces several risks that no amount of prompt engineering can fully mitigate:

**Lack of a stable audit trail.** Infrastructure changes must be attributable to a specific actor (a human approver and a pipeline run ID) for compliance purposes. An agent session does not produce a durable audit record in the same way a pipeline does.

**Prompt injection surface.** If the agent's context can be manipulated — through a malicious module description, a poisoned RAG chunk, or an adversarial developer prompt — an agent with apply permissions could be induced to destroy or misconfigure infrastructure. The pipeline, by contrast, acts only on committed, reviewed code.

**Irreversibility at scale.** A misapplied change to a shared networking module or a shared Key Vault could affect dozens of downstream workloads. The CI/CD approval gate exists precisely to impose a human moment of reflection before changes to shared or production infrastructure are committed.

**No compensation for non-determinism.** LLM outputs are probabilistic. Running the same prompt twice may produce different Terraform. The pipeline's plan-then-apply model provides a deterministic, inspectable intermediate artifact (the plan file) that precisely specifies what will change before it changes.

### The Safe Enhancement: Agentic Pipeline Interaction

The AI agent may interact with the CI/CD pipeline in a controlled, read-only-plus-trigger capacity through the CI/CD MCP server:

- **Trigger a pipeline run** for a specific PR branch (the pipeline then owns all execution).
- **Retrieve and analyze plan output** — identifying resource deletions, cost-impacting changes, or policy violations — and surface a human-readable summary to the developer within the IDE.
- **Suggest fixes** to the Terraform based on plan output, which the developer can review and commit.

This model preserves the agent's usefulness throughout the development loop while keeping all state-modifying execution firmly within the CI/CD boundary.

```
AI Agent (Analysis & Generation)          CI/CD Pipeline (Execution)
────────────────────────────────          ──────────────────────────
Generate Terraform                        Lint
       │                                  Validate
       ▼                                  Unit Tests
Validate via MCP (no state access)        Policy Check
       │                                  terraform plan ◄── AI reads this output
       ▼                                       │
Open PR via Git MCP                       Human Approval
       │                                       │
       ▼                                  terraform apply
Analyze plan output via CI/CD MCP              │
       │                                  Post-apply tests
       ▼
Suggest fixes → commit → PR update
```

---

## 4. MCP Server Deployment Architecture

The preceding sections define what the CloudNation WAM MCP server does and how it controls access to module content. This section describes how it is deployed, operated, and kept current — because a well-designed system that cannot be reliably operated is not a production-ready system.

### Deployment Platform

The MCP server is deployed as a containerised workload on **Azure Kubernetes Service (AKS)**, provisioned via the `terraform-azure-aks` WAM module. AKS is the natural choice because the MCP server shares a cluster with the Qdrant vector store, the embedding inference service, and the ingestion pipeline — all of which benefit from Kubernetes-native service discovery, network policy enforcement, and Workload Identity integration.

The deployment uses the following key products and services:

| Component | Product | Purpose |
|---|---|---|
| Container runtime | AKS (terraform-azure-aks) | Hosts all MCP server components |
| Container registry | Azure Container Registry (terraform-azure-acr) | Stores signed MCP server images |
| Identity | Azure Workload Identity | Keyless authentication to Key Vault and Qdrant |
| Secrets | Azure Key Vault (terraform-azure-kv) | GitHub App private key, Qdrant API key |
| Vector store | Qdrant (StatefulSet) | Module embeddings and metadata |
| Ingress | NGINX Ingress Controller | TLS termination, routing to MCP server pods |
| Certificate management | cert-manager + Let's Encrypt | Automated TLS certificate provisioning |
| Identity provider | Azure Entra ID | OAuth 2.0 token issuance and validation |
| Monitoring | Azure Monitor + Log Analytics (terraform-azure-law) | Audit logs, metrics, alerts |
| Image signing | cosign + sigstore | Supply chain integrity for container images |

### High-Level Deployment Steps

**Step 1 — Provision the AKS cluster and supporting infrastructure.**
The platform team applies the WAM Pattern Module for a secure AKS landing zone, which provisions the cluster, the associated Key Vault, the Container Registry, the Log Analytics workspace, and the virtual network with private endpoints. All infrastructure is managed as Terraform with the standard CloudNation CI/CD pipeline.

**Step 2 — Build and sign the MCP server container image.**
A GitHub Actions workflow builds the MCP server image from the private source repository, runs the test suite, signs the image using `cosign` with a sigstore-compatible signing key stored in Key Vault, and pushes the signed image to the Container Registry. The AKS cluster's admission controller (configured via Kyverno) rejects any pod that references an unsigned image, ensuring only verified builds can be deployed.

**Step 3 — Deploy the MCP server via Helm.**
The MCP server, Qdrant StatefulSet, and embedding service are deployed as a Helm chart from the private CloudNation Helm registry. The Helm values file specifies the Workload Identity service account, the Key Vault URI for secrets, the Qdrant collection configuration, and the Entra ID application registration details for OAuth validation. Deployment is performed by the same CI/CD pipeline used for WAM module changes — no manual `kubectl` access to production.

**Step 4 — Configure the ingestion pipeline.**
GitHub App webhooks are registered against all WAM module repositories. On every merge to `main`, the webhook fires a POST to the ingestion service's `/ingest` endpoint within the cluster. The ingestion service authenticates to GitHub using the App's private key (retrieved from Key Vault at startup), fetches the changed files, re-embeds and upserts the new vectors, and removes stale entries.

**Step 5 — Register the MCP server in developer tooling.**
The MCP server's HTTPS endpoint is published in the CloudNation internal developer portal. Developers add it to their IDE's MCP configuration with a single URL — the OAuth flow is handled transparently by the MCP host. No credentials are stored in the developer's configuration file; the token is obtained and cached by the host at session start.

### Versioning and Update Strategy

The MCP server itself is versioned independently of the WAM modules it indexes. Breaking changes to the MCP API (new tool signatures, changed resource schemas) are deployed using a **blue-green strategy**: the new version runs alongside the existing version, the ingestion pipeline indexes content into both, and a weighted traffic split in the NGINX ingress gradually shifts developer sessions to the new version. If validation failures spike — indicating that the new version is returning different or degraded context — the traffic weight is rolled back within minutes without redeployment.

WAM module content updates (new modules, changed variable schemas) do not require an MCP server deployment. The ingestion pipeline updates the vector store independently, and the next developer query retrieves the updated context automatically.

### Operational Monitoring

The Log Analytics workspace receives three streams from the MCP server:

- **Access logs** — every authenticated request, the resolved identity, the query content (sanitised), and the collections queried
- **Retrieval quality metrics** — the top-ranked chunk scores for every query, enabling detection of degraded retrieval quality when embedding model drift occurs
- **Ingestion pipeline health** — time-since-last-successful-ingest per repository, alerting the platform team if a WAM module update has not been indexed within the expected window

Alert rules fire when authentication failure rates exceed a baseline (possible credential compromise), when retrieval scores drop below a threshold (possible embedding model mismatch), or when the ingestion pipeline has not run successfully for more than 24 hours.

---
## Final Positioning

This architecture delivers a system in which the speed of AI-assisted development does not come at the expense of the governance properties that CloudNation's enterprise clients require. The MCP protocol provides the standardized language for AI-to-tool communication. The MCP host (the developer's IDE) enforces which capabilities the agent may access and under what consent conditions. The CloudNation WAM MCP server exposes only what the agent needs — curated, version-controlled, allowlisted module knowledge — and nothing more. The RAG backend ensures that what is exposed is accurate and current, eliminating the principal risk of AI-generated infrastructure code: confident generation from stale or fabricated context.

The execution boundary is not a limitation on the system's ambition — it is the feature that makes enterprise adoption possible. An AI that can generate, validate, and explain production-grade Terraform, grounded in CloudNation's proprietary WAM library, and integrated into a PR-based approval workflow, is genuinely transformative. An AI that can also apply that Terraform directly is a liability. The architecture above achieves the former while categorically preventing the latter.
