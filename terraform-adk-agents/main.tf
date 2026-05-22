terraform {
  required_version = ">= 1.6"

  cloud {
    organization = "matthewshan"
    workspaces {
      name = "terraform-adk-agents"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# ── Provider ───────────────────────────────────────────────────────────────────

provider "google" {
  project = var.project_id
  region  = var.region
}

# ── Enable Calendar API ────────────────────────────────────────────────────────

resource "google_project_service" "calendar_api" {
  project = var.project_id
  service = "calendar-json.googleapis.com"

  # Keep the API enabled even if this Terraform module is destroyed.
  disable_on_destroy = false
}

# ── Service account ────────────────────────────────────────────────────────────

resource "google_service_account" "daily_briefing" {
  project      = var.project_id
  account_id   = "daily-briefing-agent"
  display_name = "Daily Briefing Agent"
  description  = "Read-only Google Calendar access for the daily briefing ADK agent."

  depends_on = [google_project_service.calendar_api]
}

# ── Service account key ────────────────────────────────────────────────────────
# Exported as base64-encoded JSON (google provider default format).
# Retrieve with: terraform output -raw service_account_key_base64

resource "google_service_account_key" "daily_briefing" {
  service_account_id = google_service_account.daily_briefing.name
}

# ── Manual step: share your personal Google Calendar ───────────────────────────
# Terraform cannot automate access to your personal Google Calendar.
# After apply, go to Google Calendar settings and share your personal calendar
# with:
#   daily-briefing-agent@<project-id>.iam.gserviceaccount.com
# Grant the Viewer role ("See all event details").
# You can retrieve the exact service account email with:
#   terraform output service_account_email
