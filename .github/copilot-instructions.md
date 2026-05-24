# Copilot Instructions

This is a public infrastructure-as-code repository. It contains Terraform
modules for cloud resources across personal projects.

---

## Operational safety

**Never push commits or force-push branches without explicit user approval.**
Stage and show the diff first; wait for confirmation before running any
`git push` command.

---

## Documentation maintenance

**Keep the docs index below in sync with the repo.** Whenever a document is
added, removed, or renamed, update the index in this file in the same response.
When a plan moves from in-progress to complete, mark it accordingly.

### Docs index

```
docs/
  integrations/
    supabase-vector-adk.md                   # Wiring the supabase-vector module into ADK agents (schema setup, Python client, env vars)
  plans/
    plan-terraform-adk-agents-migration.md   # Migrate GCP Calendar SA from adk-playground → this repo; OpenTofu local state → HCP Terraform
  security/
    sop-secret-hygiene.md                    # SOP: preventing credential exposure in git, CI logs, and Terraform state
```

---

## Project structure

```
cloud-infrastructure/
  .github/
    copilot-instructions.md   # AI instructions — source of truth (imported by CLAUDE.md)
  CLAUDE.md                   # Claude Code entry point — imports copilot-instructions.md
  terraform-adk-agents/       # Google Calendar service account (GCP)
  supabase-vector/            # Supabase project with pgvector for ADK agent memory / RAG
  docs/
    integrations/             # How-to guides for wiring modules into ADK agents
    plans/                    # Migration and implementation plans
    security/                 # SOPs and security guidelines
  README.md
```

---

## Coding conventions

- **Terraform ≥ 1.6** (HashiCorp, not OpenTofu)
- Remote backend: **HCP Terraform** (cloud block) — never local state
- One service / concern per directory under the repo root (GCP, Supabase, etc.)
- Split each module into `main.tf`, `variables.tf`, `outputs.tf`
- Commit a `terraform.tfvars.example` documenting required variables; never commit `terraform.tfvars`
- Secret values live in HCP Terraform workspace variables (marked sensitive) — never in code or `.tfvars` files committed to git
- Provider versions: Google `~> 5.0`, Supabase `~> 1.0`
- Each new module gets its own HCP Terraform workspace named after the directory
