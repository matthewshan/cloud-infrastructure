# Copilot Instructions

This is a public infrastructure-as-code repository. It contains Terraform
modules for cloud resources across personal projects.

---

## Documentation maintenance

**Keep the docs index below in sync with the repo.** Whenever a document is
added, removed, or renamed, update the index in this file in the same response.
When a plan moves from in-progress to complete, mark it accordingly.

### Docs index

```
docs/
  plans/
    plan-terraform-adk-agents-migration.md   # Migrate GCP Calendar SA from adk-playground → this repo; OpenTofu local state → HCP Terraform
```

---

## Project structure

```
cloud-infrastructure/
  .github/
    copilot-instructions.md   # This file
  terraform-adk-agents/       # Google Calendar service account (GCP) — planned, not yet scaffolded
  docs/
    plans/                    # Migration and implementation plans
  README.md
```

---

## Coding conventions

- **Terraform ≥ 1.6** (HashiCorp, not OpenTofu)
- Remote backend: **HCP Terraform** (cloud block) — never local state
- One GCP service / concern per directory under the repo root
- Split each module into `main.tf`, `variables.tf`, `outputs.tf`
- Commit a `terraform.tfvars.example` documenting required variables; never commit `terraform.tfvars`
- Always include a `.gitignore` that excludes `*.tfstate`, `*.tfstate.*`, `.terraform/`, and `*.tfvars`
- Secret values live in HCP Terraform workspace variables (marked sensitive) — never in code or `.tfvars` files committed to git
