# Terminology Reference

**CloudNation AI-Augmented WAM — Technical Reference Glossary**

This glossary covers all technical terms, protocols, products, and concepts referenced across the CloudNation Well-Architected Modules assessment (Parts 1–3) and the CCoE pitch deck. Terms are sorted alphabetically. Each entry includes a category in brackets indicating the domain it primarily belongs to. Where a term spans multiple domains, the most relevant category is listed. Acronyms are cross-referenced to their full entries.

---

## A

**ADLS Gen2** `[Azure Platform]`
Azure Data Lake Storage Generation 2. A set of capabilities built on top of Azure Blob Storage designed for big data analytics workloads. It adds a hierarchical namespace to Blob Storage, enabling directory-level operations and fine-grained access control via POSIX-style permissions. In the CloudNation context, the `terraform-azure-sa` module supports ADLS Gen2 file systems and paths as a first-class resource type.

**Agent / AI Agent** `[AI/ML]`
A software process in which a large language model is given access to tools, memory, and a goal, and autonomously decides which actions to take in order to accomplish that goal. Unlike a chatbot that simply responds to a single prompt, an agent operates in a loop: it reasons about its current state, selects a tool to call, processes the result, and continues until the task is complete or it needs to request human input. In the CloudNation architecture, the AI agent generates Terraform, validates it via MCP tools, and opens pull requests — all without a human directing each individual step.

**Agentic AI Foundation** `[AI/ML]`
A working group under the Linux Foundation that stewards the Model Context Protocol (MCP) specification. Anthropic released MCP in November 2024 and subsequently transferred governance to this body to ensure the protocol develops as an open, vendor-neutral standard.

**AI IDE** `[AI/ML · Developer Tooling]`
An integrated development environment that embeds AI capabilities directly into the code-authoring experience. In the context of the CloudNation PoC, Cursor and Windsurf are the primary examples. These tools host the MCP client layer and present the AI's suggestions, completions, and chat responses inline alongside the developer's code.

**Allowlist / Allowlisting** `[Security]`
A security control that explicitly enumerates what is permitted, denying everything else by default. In the CloudNation WAM MCP server, module allowlisting ensures the AI can only reference module source strings that appear in an approved registry — preventing hallucinated module names, unapproved third-party sources, or outdated version references from reaching a pull request.

**ANN Search** `[AI/ML]`
Approximate Nearest-Neighbour search. An algorithm that finds the vectors in a database that are most similar to a query vector without comparing the query against every stored vector. ANN trades a small degree of recall accuracy for dramatically faster search times, making semantic search practical at scale. The CloudNation RAG backend uses Qdrant's HNSW-based ANN implementation to retrieve relevant module chunks in milliseconds.

**Anthropic** `[AI/ML]`
The AI safety company that created and trains the Claude family of large language models. Anthropic also designed and released the Model Context Protocol (MCP) in November 2024 before transferring its governance to the Linux Foundation's Agentic AI Foundation.

**Approval Gate** `[DevOps]`
A mandatory pause in a CI/CD pipeline that requires a human to review and approve a change before execution continues. In the CloudNation architecture, an approval gate is required before `terraform apply` runs in a production environment. This gate ensures that AI-generated infrastructure changes receive human review before any irreversible state change occurs.

**App Service** `[Azure Platform]`
Azure's platform-as-a-service offering for hosting web applications, REST APIs, and mobile back-ends without managing the underlying virtual machines or networking. In the CloudNation PoC, Radius running on a local kind cluster acts as a local-dev equivalent of App Service: it deploys containers, manages health checks, handles routing, and injects environment variables — all without requiring the developer to write Kubernetes YAML.

**Audit Trail** `[Security · DevOps]`
A tamper-evident, chronological record of actions taken by systems and users. In the CloudNation AI-augmented workflow, the audit trail encompasses Git commits, CI/CD pipeline run logs, and MCP session logs — linked by a correlation ID included in the pull request description. This allows an incident investigator to reconstruct exactly what the AI generated, what context it had, and which tools it invoked, for any given infrastructure change.

**Azure DevOps** `[DevOps · Azure Platform]`
Microsoft's integrated set of developer services for source control, CI/CD pipelines (Azure Pipelines), work item tracking, and artefact management. It is one of the two primary Git hosting and pipeline platforms referenced for the CloudNation WAM ingestion and deployment workflow, alongside GitHub.

**Azure Monitor Log Analytics** `[Azure Platform · Security]`
A cloud-based service within Azure Monitor that collects, queries, and analyses log data from Azure resources and applications. In the CloudNation security architecture, MCP session audit logs are written to an immutable append-only Log Analytics workspace. The immutability ensures that neither the MCP server's identity nor any developer identity can retroactively alter the audit record.

**Azure RBAC** `[Azure Platform · Security]`
Azure Role-Based Access Control. The authorisation system in Azure that controls who can perform what actions on which resources. RBAC assigns permissions through role assignments that link a security principal (a user, group, managed identity, or service principal) to a role definition at a specific scope. The `terraform-azure-kv` module defaults `enable_rbac_authorization` to `true`, enforcing RBAC over the older, less granular vault access policy model.

**azurerm** `[Terraform/IaC · Azure Platform]`
The official HashiCorp Terraform provider for Microsoft Azure. It exposes every Azure resource type — storage accounts, key vaults, virtual networks, and hundreds more — as Terraform resource blocks. CloudNation's WAM Resource Modules are wrappers around `azurerm` resources, adding typed interfaces, secure defaults, and validation rules on top of the underlying provider.

---

## B

**BAAI/bge-m3** `[AI/ML]`
An open-weight embedding model released by the Beijing Academy of Artificial Intelligence. It supports three retrieval modes simultaneously from a single model: dense vector retrieval, sparse (BM25-equivalent) retrieval, and multi-vector ColBERT-style token-level matching. It is the recommended self-hosted embedding model for CloudNation deployments where data residency requirements prevent sending proprietary module content to external APIs.

**Bicep** `[Azure Platform · Terraform/IaC]`
A domain-specific language developed by Microsoft for declaring Azure infrastructure. It compiles to ARM (Azure Resource Manager) templates and provides a cleaner, more concise syntax. In the Radius ecosystem, Bicep is the primary language for writing application definitions (`app.bicep`) and Recipes. Radius extends Bicep with an `extension radius` directive that adds its own resource types.

**Blob Storage** `[Azure Platform]`
Azure's object storage service for unstructured data such as documents, images, videos, and backup files. Blob Storage is the underlying foundation for ADLS Gen2 and is managed by the `terraform-azure-sa` module. The module enforces security defaults including HTTPS-only access, minimum TLS version, network deny-by-default, and optional container-level immutability policies.

**BM25** `[AI/ML]`
Best Match 25. A probabilistic keyword-based ranking algorithm widely used in information retrieval. It scores documents by term frequency and inverse document frequency, rewarding documents that contain rare query terms. In the CloudNation hybrid retrieval pipeline, BM25 sparse search complements dense vector search: dense search finds semantically related content, while BM25 precisely matches exact HCL identifiers such as `enable_rbac_authorization` or `azurerm_key_vault`.

---

## C

**CCoE** `[DevOps · Cloud Strategy]`
Cloud Center of Excellence. An internal team or committee responsible for defining, governing, and scaling an organisation's cloud adoption strategy. A CCoE typically owns cloud architecture standards, approved module libraries, security baselines, and the processes by which development teams consume cloud infrastructure. CloudNation's AI-augmented WAM pitch is directed at newly formed CCoEs that need to accelerate Landing Zone as a Service delivery without compromising governance.

**Certificate Issuer** `[Azure Platform · Security]`
A trusted third-party Certificate Authority (CA) integrated with Azure Key Vault that can automatically issue, renew, and manage TLS/SSL certificates. The `terraform-azure-kv` module supports configuring certificate issuers as a first-class resource, enabling automated certificate lifecycle management without manual intervention.

**Checkov** `[DevOps · Security]`
An open-source static analysis tool for infrastructure-as-code. It scans Terraform, Bicep, CloudFormation, and other IaC formats against a library of security and compliance rules, identifying misconfigurations before code is deployed. In the CloudNation QA pipeline, Checkov runs as part of the CI/CD static analysis stage. Rules already covered by the OPA policy layer are selectively disabled in Checkov to avoid duplicate reporting.

**Chunking** `[AI/ML]`
The process of dividing source documents into smaller, semantically coherent units prior to embedding them in a vector database. Chunking strategy significantly affects retrieval quality: chunks that are too large lose specificity; chunks that span unrelated content degrade precision. The CloudNation ingestion pipeline uses module-boundary chunking rather than sliding-window chunking, because Terraform modules have natural semantic boundaries — each variable schema, output block, and example is a distinct unit of meaning.

**CI/CD Pipeline** `[DevOps]`
Continuous Integration / Continuous Delivery pipeline. An automated sequence of stages that builds, tests, validates, and deploys software changes. In the CloudNation architecture, the CI/CD pipeline is the sole authority for executing `terraform plan` and `terraform apply`. The AI agent may generate code and open pull requests, but all infrastructure state changes are owned by the pipeline under a controlled, auditable service identity.

**Claude** `[AI/ML]`
The family of large language models developed by Anthropic. Claude models are noted for their strong instruction-following, reasoning, and code generation capabilities. They are a natural fit for the CloudNation AI-augmented WAM workflow given that the MCP protocol was originally designed by Anthropic.

**CloudNation** `[Cloud Strategy]`
A Netherlands-based cloud consultancy and Microsoft Gold Partner specialising in Azure infrastructure delivery, Well-Architected Frameworks, and platform engineering. CloudNation develops and maintains the Well-Architected Modules (WAM) library as both an open-source resource (Resource Modules) and a proprietary delivery methodology (Pattern Modules).

**CMK** `[Azure Platform · Security]`
Customer-Managed Key. An encryption key that the customer generates, owns, and stores in Azure Key Vault, as opposed to a platform-managed key controlled by Microsoft. Using a CMK gives an organisation full control over the encryption lifecycle for their data — including the ability to revoke access by deleting the key. The `terraform-azure-kv` module supports configuring CMKs for use with other services such as Azure Storage, via the `customer_managed_key` block.

**Conftest** `[DevOps · Security]`
An open-source tool that evaluates structured data (JSON, YAML, HCL) against policies written in Rego (the Open Policy Agent policy language). Conftest is the command-line runner used to execute OPA policies against `terraform plan` JSON output in the CloudNation QA pipeline. The `--fail-defined` flag causes Conftest to exit with a non-zero code if any policy rule is violated, halting the pipeline.

**Container Image** `[DevOps]`
A portable, immutable package that contains an application and all its runtime dependencies — code, libraries, configuration, and environment variables — bundled into a single artefact. Container images are the deployment unit in Kubernetes-based environments. In the CloudNation PoC, the Hello World application is packaged as a Docker container image, pushed to a local registry, and deployed by Radius into a kind cluster.

**Context Window** `[AI/ML]`
The maximum amount of text (measured in tokens) that a large language model can process at one time. A model's context window includes both the input prompt and the generated output. RAG-based systems work by injecting retrieved context chunks into the context window, so the model can reference accurate, current information when generating output. Larger context windows allow more retrieved chunks to be injected simultaneously.

**Contour** `[DevOps · Kubernetes]`
An open-source Kubernetes ingress controller and load balancer built on Envoy. Radius installs Contour as part of its control plane to handle HTTP/HTTPS routing from outside the cluster to application pods. In the CloudNation PoC, Contour routes traffic from `localhost:8080` on the Windows host to the Hello World container running inside the kind cluster.

**cosign** `[DevOps · Security]`
An open-source tool for signing and verifying container images, part of the Sigstore project. Using cosign with a container image ensures that the image pulled at runtime is the same image that was reviewed and approved at build time. CloudNation recommends signing the WAM MCP server's container image with cosign to prevent tool poisoning attacks that substitute a malicious image.

**Cross-Encoder** `[AI/ML]`
A type of neural network model used for relevance re-ranking in information retrieval. Unlike a bi-encoder (which embeds query and document independently and compares vectors), a cross-encoder takes both the query and a candidate document as a joint input and produces a single relevance score. This allows it to model the interaction between query and document, producing higher-precision rankings than vector similarity alone. The CloudNation RAG pipeline uses `cross-encoder/ms-marco-MiniLM-L-6-v2` to re-rank the top-20 Qdrant candidates before selecting the final 5–8 for injection.

**Cursor** `[AI/ML · Developer Tooling]`
An AI-native code editor built on VS Code that embeds LLM capabilities directly into the editing experience. Cursor acts as an MCP host in the CloudNation architecture, managing MCP client connections to the WAM MCP server, the Git MCP server, and the CI/CD MCP server simultaneously.

---

## D

**Dapr** `[DevOps · Developer Tooling]`
Distributed Application Runtime. A set of APIs and building blocks that simplify microservice development by abstracting common distributed systems concerns such as service discovery, state management, pub/sub messaging, and secret management. Radius supports Dapr building blocks as portable resources, allowing applications to declare `"I need a message queue"` without specifying the underlying broker.

**DefaultAzureCredential** `[Azure Platform · Security]`
A credential resolution chain provided by the Azure SDK that tries multiple authentication methods in sequence: environment variables, workload identity, managed identity, Azure CLI, and others. Applications built with `DefaultAzureCredential` work transparently in local development (using Azure CLI credentials) and in production Kubernetes pods (using Workload Identity), without code changes or hardcoded secrets.

**Defence in Depth** `[Security]`
A security strategy that applies multiple independent layers of protection so that a failure in any single layer does not result in a complete compromise. In the CloudNation constraint enforcement model, each validation layer (Terraform type system, tflint, OPA, CI/CD pipeline) is independently capable of blocking non-compliant code, so a bypass of one layer does not allow non-compliant infrastructure to reach production.

**Dense Vector** `[AI/ML]`
A high-dimensional numerical representation of text or other content produced by an embedding model. Every dimension carries a fractional value, and similar content produces vectors that are geometrically close to one another. Dense vectors are the foundation of semantic search: you embed a query and find the stored vectors nearest to it. Contrast with sparse vectors, where most dimensions are zero.

**Docker** `[DevOps]`
A platform for building, distributing, and running software in containers. Docker provides the container runtime and image build tooling used throughout the CloudNation PoC: building the Hello World application image, running the local registry, and providing the execution environment for the kind cluster's nodes.

**Docker Desktop** `[DevOps]`
A GUI application for Windows and macOS that installs and manages Docker, Docker Compose, and Kubernetes locally. In the CloudNation PoC, Docker Desktop with the WSL 2 backend is the prerequisite that makes kind (and therefore Radius) possible on Windows 11.

**Drift** `[Terraform/IaC]`
The condition in which the actual state of deployed infrastructure diverges from what is described in the infrastructure-as-code source. Drift occurs when resources are modified manually, outside the IaC workflow. CloudNation's WAM approach structurally reduces drift by ensuring all infrastructure is provisioned through validated modules with enforced defaults — leaving fewer degrees of freedom for manual deviation.

---

## E

**Embedding Model** `[AI/ML]`
A machine learning model that converts text, images, or other content into dense numerical vectors in a high-dimensional space, where semantically similar content maps to geometrically similar vectors. In the CloudNation RAG backend, the embedding model converts both the stored WAM module chunks and incoming agent queries into vectors that can be compared by the Qdrant vector database. The same model must be used at ingestion time and query time.

**E2E Tests** `[DevOps]`
End-to-End tests. Automated tests that validate an entire system from the user's or operator's perspective by deploying a full application stack in a sandbox environment, exercising it through its actual interfaces, and verifying that the deployment behaves as expected before destroying it. In the CloudNation QA pyramid, E2E tests sit at the top: they are the most expensive and slowest to run, so they are gated behind passing unit and integration tests.

---

## F

**FAISS** `[AI/ML]`
Facebook AI Similarity Search. An open-source library for efficient similarity search over dense vectors. It runs in-memory and lacks native metadata filtering or persistence, making it unsuitable for the CloudNation production RAG use case. Qdrant is chosen over FAISS specifically because Qdrant supports payload-based pre-filtering and durable storage.

**Feature Branch** `[DevOps]`
A Git branch created to develop a specific feature or change in isolation from the main codebase. In the CloudNation AI workflow, the AI agent commits generated Terraform to a feature branch and opens a pull request from that branch, allowing the CI/CD pipeline to validate the change before it is merged.

---

## G

**geo-redundant storage (GRS)** `[Azure Platform]`
An Azure Storage replication option that copies data to a secondary geographic region hundreds of miles from the primary. GRS provides resilience against regional outages. The `terraform-azure-sa` module defaults `account_replication_type` to `"GRS"`, meaning every storage account provisioned through CloudNation WAM is geo-redundant by default.

**Git** `[DevOps]`
A distributed version control system that tracks changes to source code over time. In the CloudNation architecture, Git is the source of truth for all WAM module definitions, application Bicep files, and OPA policies. Pull requests, commits, and branch histories provide the human-readable audit trail that complements the MCP session logs.

**GitHub Actions** `[DevOps]`
GitHub's native CI/CD platform that executes automated workflows in response to repository events such as pull requests, pushes, and scheduled triggers. In the CloudNation ingestion pipeline, a GitHub Actions workflow fires on every merge to a WAM repository's main branch, triggering re-indexing of the changed files in the Qdrant vector store.

**GitHub App** `[DevOps · Security]`
A type of GitHub integration that acts as a first-class actor with its own identity and permission scope, as opposed to a personal access token tied to an individual user account. GitHub Apps can be granted read-only permissions scoped to specific repositories, making them the secure, least-privilege authentication mechanism for the CloudNation WAM ingestion service.

**GPT** `[AI/ML]`
Generative Pre-trained Transformer. The architecture underlying OpenAI's family of large language models (GPT-3, GPT-4, GPT-4o, etc.). The term is also used colloquially to refer to any large language model, though technically GPT refers specifically to the OpenAI product line. The transformer architecture — self-attention layers trained on large text corpora — is the foundation for virtually all modern LLMs, including both OpenAI's GPT models and Anthropic's Claude.

---

## H

**Hallucination** `[AI/ML]`
The phenomenon in which a large language model generates content that is syntactically plausible but factually incorrect, referencing things that do not exist — such as a Terraform module argument that is not part of any module's actual interface, or a module source string for a repository that does not exist. In the CloudNation architecture, hallucination is mitigated structurally by RAG-based context injection, module allowlisting, and `terraform validate`, rather than relying on the model to self-correct.

**HCL** `[Terraform/IaC]`
HashiCorp Configuration Language. The domain-specific language used to write Terraform configurations. HCL is designed to be human-readable while remaining machine-parseable. CloudNation's WAM modules are written in HCL, and the AI agent generates HCL configurations that are subsequently validated by `terraform validate`, `tflint`, and OPA policies.

**Helm** `[DevOps · Kubernetes]`
The package manager for Kubernetes. Helm packages Kubernetes manifests into versioned charts that can be installed, upgraded, and rolled back with a single command. In the CloudNation PoC, Helm is used to install the Radius control plane into the kind cluster non-interactively: `helm install radius radius/radius`.

**HNSW** `[AI/ML]`
Hierarchical Navigable Small World. A graph-based algorithm for approximate nearest-neighbour search that organises vectors in a multi-layered navigable graph. Long-range connections at upper layers allow fast traversal to the approximate neighbourhood of the query, while short-range connections at lower layers enable precise local search. HNSW is the default indexing algorithm in Qdrant and is the reason ANN search in Qdrant achieves millisecond latency even over millions of vectors. The two key configuration parameters are `m` (graph connectivity, controls recall vs memory trade-off) and `ef_construct` (search depth during index construction, controls accuracy vs build time).

**Hybrid Retrieval** `[AI/ML]`
A retrieval strategy that combines dense vector search (semantic similarity) with sparse keyword search (BM25/TF-IDF) to improve the precision and recall of retrieved results. Dense search finds conceptually related content; sparse search matches exact identifiers. Combining both via Reciprocal Rank Fusion (RRF) outperforms either approach alone, particularly for technical domains like Terraform where exact identifiers (`enable_rbac_authorization`) are as important as semantic meaning.

---

## I

**IaC** `[Terraform/IaC]`
Infrastructure as Code. The practice of defining, provisioning, and managing cloud infrastructure through machine-readable configuration files rather than through manual processes or interactive GUIs. IaC enables version control, automated testing, repeatable deployments, and drift detection for infrastructure. Terraform is the primary IaC tool in the CloudNation ecosystem.

**Idempotency** `[Terraform/IaC · DevOps]`
The property of an operation that produces the same result regardless of how many times it is executed. Terraform achieves idempotency by comparing desired state (what the configuration describes) against actual state (what is recorded in the state file) and only making the changes necessary to reconcile the difference. The CloudNation PoC test lifecycle (plan → apply → validate → destroy) verifies idempotency by ensuring a module can be applied and destroyed repeatedly without side effects.

**Ingestion** `[AI/ML]`
The offline process of reading source documents (Terraform modules, READMEs), parsing and chunking them, generating embeddings, and storing the resulting vectors and metadata in a vector database. Ingestion is triggered by Git webhooks on every merge to a WAM repository's main branch, keeping the RAG backend's knowledge base current.

**int8 Quantization** `[AI/ML]`
A compression technique that converts 32-bit floating-point embedding vectors to 8-bit integers, reducing memory consumption by approximately 75% with minimal impact on retrieval accuracy. Applied to the Qdrant collection for WAM modules, int8 quantization makes the vector store operable on modest infrastructure. The `quantile: 0.99` parameter clips outlier dimension values before quantising to preserve accuracy at the tails of the distribution.

**ISV** `[Cloud Strategy]`
Independent Software Vendor. A company that develops and sells software products, as distinct from a system integrator or consultancy. CloudNation serves both enterprise clients (large organisations deploying cloud infrastructure at scale) and ISV clients (software companies embedding cloud infrastructure into their products). The distinction matters for WAM governance because ISV clients may have bespoke landing zone requirements embedded in private Pattern Modules.

---

## J

**JSON-RPC 2.0** `[Protocols]`
A remote procedure call protocol that uses JSON as its data format. It is lightweight, stateless, and transport-agnostic. The Model Context Protocol (MCP) is built on JSON-RPC 2.0 as its base message format, using it to define the request/response structure for capability negotiation, resource retrieval, and tool invocation between MCP hosts and servers.

---

## K

**Key Rotation** `[Security · Azure Platform]`
The practice of periodically replacing cryptographic keys with new ones to limit the window of exposure if a key is compromised. The `terraform-azure-kv` module supports automated key rotation policies — including notification before expiry and automatic rotation a configurable number of days before the key expires — directly enforcing the WAF Security pillar's guidance on cryptographic key hygiene.

**Key Vault** `[Azure Platform · Security]`
Azure Key Vault is a cloud service for securely storing and accessing secrets (passwords, connection strings), cryptographic keys, and certificates. It provides hardware-backed security, audit logging of all access, and fine-grained access control via Azure RBAC. The `terraform-azure-kv` CloudNation WAM module manages Key Vault deployments with secure defaults enforced by design.

**kind** `[DevOps · Kubernetes]`
Kubernetes in Docker. A tool that creates local Kubernetes clusters using Docker containers as nodes. It is the officially recommended approach for running Radius locally on Windows. Each kind node is a Docker container running a full Kubernetes control plane component, making it possible to simulate a multi-node cluster on a single laptop without a separate virtual machine.

**KServe** `[AI/ML · Kubernetes]`
An open-source Kubernetes-native platform for deploying, scaling, and managing machine learning inference services. In the CloudNation RAG architecture, KServe is the recommended way to deploy the `bge-m3` self-hosted embedding model as an inference service within the same Kubernetes cluster as the Qdrant instance, ensuring all data processing stays within the organisation's infrastructure boundary.

**Kubernetes** `[DevOps]`
An open-source container orchestration platform that automates deploying, scaling, and managing containerised applications. In the CloudNation PoC and production architectures, Kubernetes (via kind locally, or AKS in Azure) provides the runtime for the Radius control plane and the application containers it manages.

**Kubernetes Workload Identity** `[Azure Platform · Security]`
A mechanism that allows Kubernetes pods to assume Azure managed identities without storing credentials in environment variables or container images. The pod's service account is federated with an Azure Managed Identity using OpenID Connect (OIDC), allowing the pod to request short-lived access tokens automatically. The CloudNation WAM MCP server runs with a Workload Identity that grants only the specific permissions it needs — no more.

---

## L

**Landing Zone** `[Azure Platform · Cloud Strategy]`
A pre-configured, governance-ready cloud environment that provides the foundational networking, identity, security, and compliance infrastructure upon which workloads are deployed. A landing zone is defined by a set of policies, role assignments, resource groups, virtual networks, and management configurations that enforce an organisation's cloud governance model. CloudNation's LZaaS (Landing Zone as a Service) offering delivers these environments through WAM Pattern Modules.

**Lateral Movement** `[Security]`
A technique in which an attacker who has compromised one component uses that foothold to access other components in the same environment. In the CloudNation MCP security model, lateral movement is prevented by giving the WAM MCP server a Workload Identity with minimal permissions and a Kubernetes NetworkPolicy that restricts outbound connections to only the specific endpoints the server legitimately needs.

**LLM** `[AI/ML]`
Large Language Model. A type of artificial intelligence model trained on vast quantities of text data to understand and generate human language. LLMs use the transformer architecture and operate by predicting the next token in a sequence given all preceding tokens. Modern LLMs (GPT-4, Claude, Llama, Qwen) exhibit emergent capabilities including code generation, reasoning, summarisation, and instruction-following. In the CloudNation architecture, the LLM is the probabilistic component that generates Terraform — it is explicitly not trusted to enforce compliance, which is delegated to deterministic validation systems.

**llama3.1** `[AI/ML]`
A family of open-weight large language models developed by Meta. In the CloudNation PoC, `llama3.1:8b` is the recommended chat and generation model for developers running Ollama locally on consumer hardware. The 8-billion parameter variant runs on CPU at acceptable latency and produces competent Terraform and Bicep output when grounded by WAM module context.

**Log Analytics Workspace** `[Azure Platform]`
See *Azure Monitor Log Analytics*.

**LZaaS** `[Cloud Strategy · Azure Platform]`
Landing Zone as a Service. A delivery model in which a CCoE or cloud platform team provides pre-configured, compliant cloud environments to internal teams or clients on demand, without requiring each consumer to design or implement the foundational infrastructure themselves. CloudNation's AI-augmented WAM architecture accelerates LZaaS delivery by reducing the lead time from days or weeks to hours.

---

## M

**Managed Identity** `[Azure Platform · Security]`
An Azure Active Directory identity automatically managed by the Azure platform and assigned to an Azure resource such as a virtual machine, Azure Functions app, or AKS pod. Managed identities eliminate the need to store credentials in code or configuration — the resource requests tokens directly from Azure AD using its identity. CloudNation WAM modules use managed identities as the preferred authentication mechanism for inter-service connectivity.

**Matryoshka Representation Learning (MRL)** `[AI/ML]`
A training technique that allows an embedding model to produce vectors of variable dimensionality from a single model, where lower-dimensional vectors are simply the leading dimensions of the full-size vector. OpenAI's `text-embedding-3-large` supports MRL, allowing its 3072-dimensional output to be reduced to 1536 dimensions with minimal quality loss — halving storage and compute costs while retaining most retrieval accuracy.

**MCP** `[Protocols · AI/ML]`
Model Context Protocol. An open communication standard defined by Anthropic (now governed by the Linux Foundation's Agentic AI Foundation) that specifies how AI models can discover and invoke external capabilities — Resources (read-only data), Tools (executable functions), and Prompts (reusable instruction templates). MCP is transport-agnostic, supporting stdio for local processes and Server-Sent Events/HTTP for remote services. It is built on JSON-RPC 2.0. The three architectural roles in MCP are the Host (which contains the AI and enforces policy), the Client (a 1:1 session manager for a specific server), and the Server (which exposes capabilities).

**MCP Client** `[Protocols · AI/ML]`
A protocol-layer component embedded within an MCP Host that maintains a dedicated, stateful session with a single MCP Server. A Host can manage multiple Clients simultaneously, each isolated from the others. Each Client handles protocol negotiation, capability exchange, and bidirectional message routing for its paired Server.

**MCP Host** `[Protocols · AI/ML]`
The process that contains the AI model and acts as the security broker and orchestrator for MCP sessions. The Host creates and manages MCP Clients, enforces which Servers they may connect to, handles user consent, aggregates context from multiple Servers, and coordinates the LLM's inference calls. In the CloudNation developer context, the Host is the AI IDE (Cursor or Windsurf) or a custom CLI agent.

**MCP Server** `[Protocols · AI/ML]`
A service that exposes capabilities to an AI model via the MCP protocol. An MCP Server responds to requests from its paired Client, returning Resources, executing Tools, and offering Prompts. Critically, an MCP Server has no visibility into the broader conversation — it receives only the information its Client forwards to it. The CloudNation WAM MCP Server exposes module metadata, naming conventions, and the `validate_hcl` tool as MCP primitives.

**Metadata Filtering** `[AI/ML]`
Applying structured attribute filters to narrow the search space in a vector database before the ANN search executes. In Qdrant, metadata filtering uses payload fields — such as `stability = "stable"` or `module_name = "terraform-azure-kv"` — to restrict the candidate set. Pre-filtering before the vector search is critical for correctness: it ensures that deprecated or draft modules are never returned, even if their embedding vectors are geometrically closest to the query.

**Mistune / markdown-it-py** `[AI/ML · Developer Tooling]`
Python libraries for parsing Markdown documents. In the CloudNation RAG ingestion pipeline, these libraries are used to parse module README and documentation files into structured text before embedding, complementing `python-hcl2`'s parsing of `.tf` files.

---

## N

**Network ACL / Network Access Control List** `[Azure Platform · Security]`
A set of rules that control inbound and outbound network traffic at the Azure resource level. The `terraform-azure-kv` module defaults `network_acls.default_action` to `"Deny"`, meaning all traffic is blocked unless an explicit IP rule or VNet subnet rule permits it. This implements the principle of least-privilege networking, preventing accidental public exposure.

**NetworkPolicy** `[Kubernetes · Security]`
A Kubernetes resource that specifies how pods are allowed to communicate with each other and with external endpoints. In the CloudNation MCP security architecture, the WAM MCP server pod runs in a namespace with an egress NetworkPolicy that allows outbound connections only to the private Git repositories, the Qdrant vector store, and Azure Key Vault — all other outbound traffic is denied, limiting the blast radius of a successful prompt injection attack.

**nomic-embed-text** `[AI/ML]`
An open-source text embedding model published by Nomic AI, available through Ollama. It produces 768-dimensional dense vectors and is the recommended embedding model for the CloudNation PoC's local development environment, providing the `@codebase` and `@folder` semantic search capabilities in the Continue extension.

---

## O

**OIDC** `[Security · Protocols]`
OpenID Connect. An identity layer built on top of the OAuth 2.0 protocol that allows services to verify the identity of a user or workload using short-lived cryptographic tokens issued by a trusted identity provider. In the CloudNation pipeline execution model, `terraform apply` runs under an OIDC-authenticated service identity with short-lived credentials — ensuring that the pipeline identity is distinct from any developer or AI agent identity and that credentials cannot be stolen for reuse.

**Ollama** `[AI/ML · Developer Tooling]`
An open-source tool that packages and runs large language models locally on a developer's machine. Ollama manages model downloads, quantisation, and a local inference server (accessible at `http://localhost:11434`) that exposes a compatible API. In the CloudNation PoC, Ollama runs the chat model (`llama3.1:8b`), the autocomplete model (`qwen2.5-coder:7b`), and the embedding model (`nomic-embed-text`) on the developer's Windows 11 laptop.

**OPA** `[DevOps · Security]`
Open Policy Agent. A general-purpose policy engine that evaluates structured data (JSON, YAML) against policies written in Rego, a declarative query language. In the CloudNation architecture, OPA is used to evaluate `terraform plan` JSON output against security policies — catching misconfigurations that are syntactically valid Terraform but semantically violate the WAF security baseline, such as a Key Vault deployed without purge protection.

**optional()** `[Terraform/IaC]`
A Terraform type modifier that marks a variable attribute as optional, allowing callers to omit it while specifying a default value that is used when it is absent. CloudNation WAM modules make extensive use of `optional()` to provide secure defaults while preserving full configurability: a developer who provides only the required fields automatically receives all security defaults, while an advanced engineer can override any attribute they choose.

---

## P

**Pattern Module** `[Terraform/IaC · Cloud Strategy]`
A CloudNation WAM module that composes multiple Resource Modules into a complete, opinionated, production-ready architectural pattern. Pattern Modules encode CloudNation's institutional knowledge of how to wire Azure resources together correctly — security baselines, naming conventions, compliance controls, and environment-specific variations. They are kept private to protect CloudNation's intellectual property and competitive advantage. Consumers specify only high-level intent; the Pattern Module handles all architectural decisions.

**Pinecone** `[AI/ML]`
A managed, proprietary vector database service. It is evaluated and rejected for the CloudNation use case because of its US-hosted nature, which creates potential data residency concerns for European clients whose proprietary Pattern Module content must not leave EU infrastructure boundaries.

**Policy-as-Code** `[DevOps · Security]`
The practice of expressing compliance, security, and governance rules as machine-readable code that can be version-controlled, tested, and automatically enforced in a CI/CD pipeline. In the CloudNation architecture, OPA Rego policies and tflint rulesets are the primary policy-as-code artifacts, enforcing the WAF security baseline in a way that is auditable, reviewable, and independently enforced from the AI's output.

**Private Endpoint** `[Azure Platform · Security]`
An Azure network interface that connects a service to a virtual network using a private IP address, eliminating exposure to the public internet. Resources accessed via private endpoints are not reachable from outside the VNet by default. CloudNation WAM modules support private endpoint configuration for Key Vault, Storage Account, and other services, directly implementing the WAF Security pillar's network isolation guidance.

**Prompt** `[AI/ML]`
In the MCP context, a Prompt is one of the three primitive types exposed by an MCP Server — alongside Resources and Tools. A Prompt is a reusable, parameterisable instruction template that the MCP Server provides to the AI to guide generation for a specific task. For example, the CloudNation WAM MCP Server exposes scaffolding Prompts that pre-populate the AI's context with the correct module structure for common patterns.

**Prompt Injection** `[Security · AI/ML]`
An attack in which malicious instructions are embedded in content that the AI model processes as data — such as a module's README, a pull request comment, or a Git commit message — with the intent of hijacking the model's behaviour. A successful prompt injection can cause the AI to perform actions the user did not authorise, exfiltrate data, or bypass security controls. It is the most documented and most dangerous class of vulnerability specific to AI agents with tool access.

**Pull Request (PR)** `[DevOps]`
A request to merge changes from a feature branch into a main or target branch in a Git repository. Pull requests provide a structured review point where human engineers can inspect AI-generated Terraform before it is merged and deployed. The CloudNation architecture uses PRs as the authoritative handoff point between the AI-assisted authoring phase and the pipeline-controlled execution phase.

**Purge Protection** `[Azure Platform · Security]`
An Azure Key Vault setting that prevents any principal — including subscription administrators — from permanently deleting a vault or its contents until the configured soft-delete retention period has elapsed. The `terraform-azure-kv` module defaults `purge_protection_enabled` to `true`, implementing the WAF Reliability pillar's guidance on protecting against accidental or malicious data loss.

**python-hcl2** `[Terraform/IaC · AI/ML]`
A Python library for parsing HashiCorp Configuration Language (HCL) files into Python dictionaries. In the CloudNation RAG ingestion pipeline, `python-hcl2` parses `.tf` files to extract structured module metadata — variable schemas, output definitions, resource types — which is more token-efficient and retrieval-precise than embedding raw HCL text.

---

## Q

**Qdrant** `[AI/ML]`
An open-source vector database and similarity search engine, deployable as a Kubernetes StatefulSet or as a managed cloud service (Qdrant Cloud). It supports dense and sparse vector storage, payload-based metadata filtering, HNSW indexing, scalar quantization, and role-based access control via API keys. It is the recommended vector store for the CloudNation RAG backend, chosen over FAISS (no persistence or metadata filtering) and Pinecone (proprietary, data residency concerns).

**qwen2.5-coder** `[AI/ML]`
A family of open-weight code-specialised language models developed by Alibaba's Qwen team. The `qwen2.5-coder:7b` variant is recommended for inline code autocomplete in the CloudNation PoC because of its strong HCL, Bicep, and Python awareness and its fast inference latency, making it suitable for real-time suggestions in a developer's IDE.

---

## R

**rad CLI** `[DevOps · Developer Tooling]`
The command-line interface for the Radius application platform. The `rad` binary is used to initialise Radius environments, deploy application definitions (`rad deploy app.bicep`), manage workspaces, register Recipes, expose containers for local testing, and inspect the application dependency graph (`rad app graph`).

**RAG** `[AI/ML]`
Retrieval-Augmented Generation. A technique for improving LLM output accuracy by retrieving relevant information from a trusted external source at query time and injecting it into the model's context window before generation. Rather than relying on knowledge baked into the model's weights during training, RAG provides the model with current, specific, authoritative context. In the CloudNation architecture, the RAG backend retrieves the correct WAM module definitions to ground the AI's Terraform generation, preventing hallucination of module names, arguments, and configurations.

**Radius** `[DevOps · Developer Tooling]`
An open-source application platform developed by Microsoft that runs on Kubernetes. Radius introduces the concept of Recipes — environment-level mappings that translate a developer's portable resource declaration into concrete infrastructure without the developer specifying implementation details. Locally, Recipes deploy containers in kind; in Azure, the same Recipe can invoke a CloudNation WAM Pattern Module. Radius is the local-dev equivalent of Azure App Service in the CloudNation PoC.

**RBAC** `[Security · Azure Platform]`
Role-Based Access Control. See *Azure RBAC*.

**Recipe (Radius)** `[DevOps · Developer Tooling]`
A Radius concept that maps a portable resource type declaration (e.g., `Applications.Datastores/sqlDatabases`) to a concrete implementation for a specific environment. In a `local-dev` environment, the SQL Recipe deploys a SQL Server container in kind. In a production Azure environment, the same Recipe could call a CloudNation WAM Pattern Module to provision an Azure SQL database with all Well-Architected defaults. The application definition does not change; only the Recipe changes.

**Reciprocal Rank Fusion (RRF)** `[AI/ML]`
A score-combination algorithm used to merge ranked result lists from multiple retrieval methods. Each candidate is assigned a score inversely proportional to its rank in each list, and scores are summed across lists. RRF is used in the CloudNation hybrid retrieval pipeline to combine the ranked results from dense vector search and sparse BM25 search into a single merged ranking before cross-encoder re-ranking.

**Rego** `[DevOps · Security]`
A declarative policy language used by Open Policy Agent (OPA). Rego policies are structured as rules that evaluate structured input (JSON) and produce allow/deny decisions. In the CloudNation QA pipeline, Rego policies evaluate `terraform plan` JSON to enforce security requirements such as mandatory purge protection on Key Vaults and deny-by-default network rules on storage accounts.

**Resource Module** `[Terraform/IaC]`
A CloudNation WAM module that encapsulates exactly one Azure resource type. Resource Modules provide typed, validated interfaces over the underlying `azurerm` Terraform resources, applying secure defaults while remaining fully configurable. They are published as open-source on GitHub and the Terraform Registry to build community trust and promote standard implementations. Examples include `terraform-azure-kv` and `terraform-azure-sa`.

**RRF** `[AI/ML]`
See *Reciprocal Rank Fusion*.

**Rug Pull** `[Security · AI/ML]`
A class of MCP vulnerability in which a tool's description or behaviour changes after the client has already registered and trusted it, allowing an attacker who can modify the server to introduce malicious instructions that were not present during the initial review. CloudNation mitigates rug pulls by pinning the WAM MCP Server to a specific immutable container image tag and by running it in a network-isolated container that cannot reach update servers at runtime.

---

## S

**Sampling** `[AI/ML]`
In the MCP specification, Sampling is the mechanism by which an MCP Server can request the Host to perform an LLM inference call on its behalf. This allows Servers to leverage the Host's model without having direct access to it, and keeps the Host in control of all inference calls.

**Sandbox Subscription** `[Azure Platform · DevOps]`
A dedicated Azure subscription used exclusively for testing and validation. In the CloudNation QA pipeline, integration and E2E tests deploy real Azure resources into a sandbox subscription where they are validated and then destroyed. Using a separate subscription ensures test infrastructure is isolated from production and that costs are bounded and attributable.

**Scalar Quantization** `[AI/ML]`
See *int8 Quantization*.

**Secrets** `[Security · Azure Platform]`
In the context of Azure Key Vault, a Secret is a key-value pair for storing sensitive configuration data such as passwords, connection strings, and API keys. Key Vault manages access logging, expiry, and versioning for secrets. In Terraform state files, secrets can appear as output values and must be declared with `sensitive = true` to prevent exposure in plan output or AI context windows.

**Service Principal** `[Azure Platform · Security]`
An identity in Azure Active Directory that represents an application or service, as distinct from a human user. Service principals are used by CI/CD pipelines to authenticate to Azure and execute `terraform apply`. In the CloudNation execution boundary model, the pipeline's service principal holds the production credentials; the AI agent and MCP server have no access to them.

**Sigstore** `[DevOps · Security]`
An open-source project that provides transparent, auditable, and free code signing for software artefacts including container images. The `cosign` tool, part of Sigstore, is used in the CloudNation security architecture to sign the WAM MCP Server's container image, enabling verification that the running image has not been tampered with.

**Soft Delete** `[Azure Platform · Security]`
An Azure Key Vault feature that retains deleted vaults, keys, secrets, and certificates for a configurable retention period (up to 90 days) rather than permanently destroying them immediately on deletion. The `terraform-azure-kv` module defaults `soft_delete_retention_days` to 90, providing a recovery window for accidental or malicious deletions.

**Sparse Vector** `[AI/ML]`
A high-dimensional vector in which most dimensions are zero, with non-zero values only for dimensions corresponding to terms that appear in the document. Sparse vectors are the output of keyword-based ranking algorithms like BM25 and TF-IDF. In Qdrant's hybrid retrieval mode, sparse vectors are stored alongside dense vectors, enabling a single collection to serve both semantic and keyword search.

**SSE** `[Protocols]`
Server-Sent Events. A web standard that allows a server to push a stream of events to a client over a persistent HTTP connection. SSE is one of the two transport mechanisms supported by MCP (alongside stdio) for communication between an MCP Host and a remote MCP Server. SSE is appropriate for MCP servers running as remote services, such as the CloudNation WAM MCP Server deployed in Kubernetes.

**State File** `[Terraform/IaC]`
A JSON file (typically `terraform.tfstate`) that Terraform uses to record the current state of deployed infrastructure. The state file maps every resource defined in the configuration to its corresponding real-world resource, enabling Terraform to determine what changes are needed on the next `terraform apply`. State files frequently contain sensitive data and must be stored securely — in the CloudNation architecture, in an Azure Blob Storage backend with RBAC-controlled access.

**stdio** `[Protocols]`
Standard Input/Output. The communication channel between a process and its host shell. stdio is one of the two transport mechanisms supported by MCP, used when the MCP Server runs as a local subprocess of the Host application. In the CloudNation PoC, stdio transport is used for the MCP Filesystem Server that gives Continue access to the local `radius-poc` workspace files.

---

## T

**terraform apply** `[Terraform/IaC]`
The Terraform command that executes the changes described in a plan, creating, updating, or destroying real infrastructure resources to match the desired configuration. In the CloudNation architecture, `terraform apply` is exclusively executed by the CI/CD pipeline under a controlled service identity with human approval required for production environments. The AI agent is categorically prohibited from triggering this command.

**terraform fmt** `[Terraform/IaC]`
A Terraform command that reformats HCL configuration files to a canonical style defined by HashiCorp. Running `terraform fmt --check` in CI fails the pipeline if any file is not formatted correctly, ensuring consistent code style across all WAM modules regardless of whether they were written by a human or an AI.

**terraform plan** `[Terraform/IaC]`
A Terraform command that computes the difference between the current state and the desired configuration, producing a plan that describes exactly which resources will be created, updated, or destroyed — without executing any changes. The plan output in JSON format is consumed by OPA/Conftest for policy validation. The AI agent may read the plan output via the CI/CD MCP Server but may not trigger `terraform plan` directly against production infrastructure.

**terraform validate** `[Terraform/IaC]`
A Terraform command that checks a configuration for syntactic correctness and internal consistency without accessing any remote state or APIs. It validates that all required arguments are present, all attribute types match their declarations, and all module references can be resolved. In the CloudNation MCP validation layer, `terraform validate` is the first automated check applied to AI-generated HCL.

**Terraform Provider** `[Terraform/IaC]`
A plugin that enables Terraform to interact with a specific cloud platform, service, or API. The `azurerm` provider is the Terraform provider for Microsoft Azure. The `azurerm` provider version is pinned in all CloudNation WAM modules to ensure consistent behaviour and prevent breaking changes from new provider releases.

**Terraform Registry** `[Terraform/IaC]`
The public registry at `registry.terraform.io` where Terraform modules and providers are published and discovered. CloudNation's open-source Resource Modules are published to the Terraform Registry, making them discoverable and consumable by the broader community using the standard `module { source = "CloudNationHQ/kv/azure" }` syntax.

**Terratest** `[Terraform/IaC · DevOps]`
A Go testing library for infrastructure code that allows writing automated tests that actually deploy resources, validate their properties via API calls, and then destroy them. In the CloudNation QA pyramid, Terratest is used for integration and E2E tests that need to verify real resource properties — such as whether RBAC role assignments were correctly applied between a Key Vault and a Storage Account.

**tflint** `[Terraform/IaC · DevOps]`
A Terraform linter that enforces naming conventions, detects common mistakes, and applies custom ruleset plugins. CloudNation uses a custom tflint ruleset (distributed as part of the WAM MCP Server's validation package) to enforce resource naming patterns, required tag schemas, and approved module source prefixes — catching violations that Terraform's own type system cannot express.

**TLS** `[Security · Protocols]`
Transport Layer Security. A cryptographic protocol that encrypts data in transit between a client and a server. The `terraform-azure-sa` module defaults `min_tls_version` to `"TLS1_2"`, enforcing a minimum of TLS 1.2 for all storage account connections. TLS versions below 1.2 are vulnerable to known attacks (POODLE, BEAST) and are not permitted in CloudNation WAM deployments.

**Token** `[AI/ML]`
The basic unit of text that LLMs process. Tokens are not the same as words — a single word may be split into multiple tokens, and common short words may be a single token. Token count determines how much text fits in a model's context window and how much an API call costs. Chunking strategies in RAG systems are designed to keep chunks within a target token range.

**Tool (MCP)** `[Protocols · AI/ML]`
One of the three primitive types exposed by an MCP Server. A Tool is an executable function that the AI can invoke via the MCP protocol — for example, the `validate_hcl` tool exposed by the CloudNation WAM MCP Server. Tools can perform computations, call external APIs, read files, or execute processes. Unlike Resources (read-only), Tools may have side effects. In the CloudNation architecture, the WAM MCP Server exposes only validation and query tools — never state-modifying tools like `deploy` or `apply`.

**Tool Poisoning** `[Security · AI/ML]`
An attack in which hidden instructions embedded in an MCP Server's tool descriptions cause the AI agent to invoke a tool with unintended parameters or perform actions the user did not authorise. Because tool descriptions are part of the AI's instruction context, malicious content in a description can override the user's intent. CloudNation mitigates tool poisoning by deploying the WAM MCP Server as an immutable, signed container image and requiring tool description changes to undergo the same PR review process as any other code change.

---

## V

**validate_hcl** `[Terraform/IaC · AI/ML]`
The primary MCP Tool exposed by the CloudNation WAM MCP Server. When invoked with AI-generated Terraform, it sequentially runs `terraform init`, `terraform validate`, module allowlist checking, and `tflint` with the CloudNation ruleset. Structured pass/fail results are returned to the AI, which iterates until all checks pass before opening a pull request.

**Vector Database** `[AI/ML]`
A specialised database designed to store, index, and query high-dimensional vectors efficiently. Vector databases enable semantic search by finding the stored vectors most similar (nearest) to a query vector. Qdrant is the vector database used in the CloudNation RAG architecture, storing embeddings of WAM module chunks alongside structured metadata payloads.

**VNet** `[Azure Platform]`
Azure Virtual Network. The fundamental networking building block in Azure, providing isolated, private network segments within which Azure resources communicate. CloudNation WAM modules enforce private networking by default: Key Vaults and Storage Accounts are configured to deny public access and accept connections only from within specified VNet subnets or from IP ranges explicitly allowlisted.

---

## W

**WAF** `[Azure Platform · Cloud Strategy]`
Azure Well-Architected Framework. Microsoft's set of guiding principles and best practices for designing reliable, secure, efficient, cost-effective, and operationally excellent cloud workloads on Azure. The WAF defines five pillars: Security, Reliability, Performance Efficiency, Cost Optimization, and Operational Excellence. CloudNation WAM modules translate these theoretical pillars into concrete, enforceable Terraform defaults.

**WAM** `[Terraform/IaC · Cloud Strategy]`
Well-Architected Modules. CloudNation's library of Terraform modules designed to implement the Azure Well-Architected Framework's principles as code. WAM consists of two layers: Resource Modules (single-resource building blocks, open-source) and Pattern Modules (multi-resource architectural patterns, proprietary). WAM is the core product through which CloudNation delivers governed, compliant Azure infrastructure to enterprise and ISV clients.

**Webhook** `[DevOps · Protocols]`
An HTTP callback that one system sends to another when a specified event occurs. In the CloudNation RAG ingestion pipeline, Git webhooks fire on every merge to a WAM repository's main branch, triggering the ingestion service to re-parse, re-embed, and re-index the changed files in Qdrant. This keeps the RAG knowledge base current without requiring manual reindexing.

**Windsurf** `[AI/ML · Developer Tooling]`
An AI-native code editor developed by Codeium that, like Cursor, acts as an MCP Host in the CloudNation architecture. Windsurf embeds LLM capabilities for code generation, editing, and chat alongside a developer's codebase.

**WORM** `[Security · Azure Platform]`
Write Once, Read Many. A data storage policy that prevents modification or deletion of data once it has been written, for a specified retention period. Azure Storage container immutability policies implement WORM compliance. The `terraform-azure-sa` module supports `immutability_policy` blocks at the container level, enabling regulatory compliance for audit logs, financial records, and other data that must not be altered — a common requirement in financial services and healthcare.

---

## Z

**Zero Trust** `[Security]`
A security model based on the principle of "never trust, always verify" — no actor, whether inside or outside the network perimeter, is trusted by default. Access is granted based on continuous verification of identity, device health, and context. In the CloudNation AI integration architecture, Zero Trust is applied to the AI agent itself: all AI-generated output is treated as untrusted input and validated by deterministic, policy-based systems before any infrastructure change occurs.

---

*Glossary compiled from: CloudNation Technical Assessment Parts 1–3 and CCoE Pitch Deck — March 2026.*
*Categories: AI/ML · Azure Platform · Cloud Strategy · DevOps · Developer Tooling · Kubernetes · Protocols · Security · Terraform/IaC*
