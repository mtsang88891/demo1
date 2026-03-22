# AI-Augmented Infrastructure Delivery

Technical assessment submission for CloudNation — March 2026 — David Rikkoert

---

## Original Assignment

> CloudNation Technical Assessment: AI-Augmented Infrastructure

### Context

At CloudNation, we rely heavily on our Well-Architected Modules (WAM) to deliver
secure, standardized, and compliant cloud infrastructure to our enterprise and ISV
clients. As we look to the near future, we envision utilizing agentic AI to
accelerate the creation, consumption, and updating of these modules. The Model
Context Protocol (MCP) is rapidly becoming the industry standard for securely
connecting AI agents to external tools and data sources.

### Objective

Research CloudNation's WAM methodology and design a conceptual architecture where
an AI agent — connected via an MCP server — can assist developers in autonomously
selecting, configuring, and deploying CloudNation infrastructure, while strictly
adhering to our Well-Architected and security standards.

### Part 1: Architecture & WAM Conceptualization

- Explain the architectural difference between Resource Modules and Pattern Modules.
- Why are Resource Modules open-source while Pattern Modules are kept private?
- How do these modules translate to the pillars of the Azure/AWS Well-Architected Framework?

### Part 2: AI Agent & MCP Integration Design

- Design a conceptual developer workflow using an AI IDE connected to a CloudNation MCP server.
- Design the backend ingestion/retrieval mechanism (RAG or dynamic context loading) for the MCP server.
- Define the boundary between AI assistance and automated execution for terraform plan and terraform apply.

### Part 3: Governance, Security & Testing

- How do you enforce CloudNation's mandatory input variable typing and naming conventions?
- How should an AI agent interact with CI/CD pipelines to validate its own code changes?
- What are the primary security risks of giving an LLM access to infrastructure state via MCP, and how do you mitigate them?

### Part 4: The CCoE Pitch

Prepare a presentation deck for a client's Cloud Center of Excellence (CCoE) explaining how
AI-Augmented WAM via MCP will:

- Accelerate Landing Zone as a Service (LZaaS) deployments
- Reduce technical debt
- Upskill engineering teams

---

## Deliverables

| File | Description |
|---|---|
| [part1-wam-conceptualization.md](part1-wam-conceptualization.md) | Module typology, open-source strategy, Well-Architected bridge |
| [part2-mcp-integration-design.md](part2-mcp-integration-design.md) | MCP architecture, RAG backend, developer workflow |
| [part3-governance-security-testing.md](part3-governance-security-testing.md) | Constraint enforcement, QA pipeline, security guardrails |
| [part4-ccoe-pitch.pptx](part4-ccoe-pitch.pptx) | CCoE executive pitch deck — 12 slides with speaker notes (EN/NL) |

---

## AI Tools Used

This assessment was completed with deliberate and iterative use of AI tooling throughout. The approach was not to use AI as a drafting shortcut, but as a thinking partner — pushing back on outputs, grounding responses in real artefacts, and directing the AI with specific architectural constraints rather than open-ended prompts.

### How AI was used in practice

**Starting point — ChatGPT (OpenAI).** The assessment was initially explored using ChatGPT for a first pass at framing the WAM module typology and MCP architecture questions. This produced useful initial structure but surface-level answers — particularly for the RAG backend design and the security guardrails sections, where the responses were generic rather than grounded in CloudNation's actual public module library or documented MCP vulnerabilities.

**Switching to Claude (Anthropic).** After the initial ChatGPT session, the work shifted entirely to Claude Sonnet. Claude proved significantly better suited for this assessment for three reasons: it handles long technical documents with deep cross-referencing coherently across a multi-hour session; it grounds its responses in provided artefacts (the actual `variables.tf` and `README.md` content from the CloudNation public repos) rather than hallucinating plausible-sounding examples; and it responds well to being challenged — when an answer was vague or inconsistent with the module code, pushing back produced a more precise revision rather than a defensive reiteration.

**How Claude was specifically directed:**
- The actual `variables.tf` schemas from `terraform-azure-kv` and `terraform-azure-sa` were fetched directly from GitHub and provided as context, ensuring the Terraform examples in Part 1 reference real argument names and real defaults rather than invented ones.
- For the RAG backend section in Part 2, the prompt explicitly required candidate tooling names, configuration parameters, and justification for choices — not just a high-level description. The Qdrant collection YAML and HNSW parameter discussion came from directing Claude to specify, not just to describe.
- For the security guardrails in Part 3, Claude was asked to ground each risk in a named, documented real-world incident rather than generic threat categories. The CVE references and the Invariant Labs GitHub MCP injection example came from that direction.
- The CCoE pitch deck was generated programmatically using the `pptxgenjs` library via Claude's computer use capability, with the CloudNation brand palette reverse-engineered from the public website and applied consistently across all 12 slides.
- Throughout the session, Claude was used to read and directly modify files on the local Windows machine via the Windows-MCP extension, allowing iterative refinement of all four deliverable files without manual copy-paste.

**Local AI demonstrator — Ollama + Continue.** In parallel with the written deliverables, a local technical demonstrator was built to validate the core concept: that an AI agent grounded in CloudNation's public module library can generate WAM-idiomatic Terraform from a plain-English prompt. This used `qwen2.5-coder:7b` running locally via Ollama, connected to VS Code's Continue extension, with the full set of cloned CloudNation public modules as retrieval context. The demonstrator confirmed both the feasibility of the approach and its current limitations with smaller local models — informing the model-size recommendations in Part 2.

### Tool summary

| Tool | Role in this assessment |
|---|---|
| Claude Sonnet (Anthropic) | Primary reasoning partner — architecture design, all written responses, pitch deck generation, file editing via Windows-MCP |
| ChatGPT (OpenAI) | Initial framing session — superseded by Claude for all substantive work |
| Ollama — qwen2.5-coder:7b | Local LLM for the Continue-based WAM Terraform generation demonstrator |
| Continue (VS Code extension) | AI IDE for the local demonstrator — grounded in cloned CloudNation module repos |
| Windows-MCP extension | Allowed Claude to read and write files directly on the local machine during this session |


---

## Terminology Reference

The assessment makes use of a wide range of technical terms spanning cloud architecture,
AI tooling, infrastructure as code, and security — not all of which will be familiar to
every reader. A comprehensive glossary is provided in
[terminology-reference.md](terminology-reference.md) covering all acronyms, protocols,
products, and concepts referenced across Parts 1–4.

This includes terms such as WAM, MCP, RAG, WDAC, OPA, Qdrant, LZaaS, CCoE, RBAC,
and approximately 150 further entries, each with a category tag indicating its domain
(Azure Platform, AI/ML, Developer Tooling, Security, etc.) and a plain-English
explanation in the context of this assessment.

Readers unfamiliar with any term encountered in the deliverables are encouraged to
consult the glossary first.
---

## Notes

- All Terraform examples reference real CloudNation public modules from [github.com/CloudNationHQ](https://github.com/CloudNationHQ)
- The pitch deck (part4) includes speaker notes in both English and Dutch