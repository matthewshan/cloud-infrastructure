terraform {
  required_version = ">= 1.6"

  cloud {
    organization = "matthewshan"
    workspaces {
      name = "supabase-vector"
    }
  }

  required_providers {
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
  }
}

# ── Provider ───────────────────────────────────────────────────────────────────

provider "supabase" {
  # Reads SUPABASE_ACCESS_TOKEN env var automatically.
  # Set var.supabase_access_token as a sensitive HCP Terraform workspace variable.
  access_token = var.supabase_access_token
}

# ── Supabase project ───────────────────────────────────────────────────────────

resource "supabase_project" "vector_db" {
  organization_id   = var.organization_id
  name              = var.project_name
  database_password = var.database_password
  region            = var.region
}

# ── pgvector ───────────────────────────────────────────────────────────────────
# The `vector` extension is enabled by default on all new Supabase projects.
# No extra configuration is required.
#
# One-time schema setup (run after first apply):
#   See docs/integrations/supabase-vector-adk.md for the CREATE TABLE / function
#   SQL to run before wiring this project into ADK agents.
