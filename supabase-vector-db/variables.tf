variable "supabase_access_token" {
  description = "Supabase personal access token. Generate at app.supabase.com/account/tokens. Mark sensitive in HCP Terraform."
  type        = string
  sensitive   = true
}

variable "organization_id" {
  description = "Supabase organization ID (visible in the Supabase dashboard URL)."
  type        = string
}

variable "project_name" {
  description = "Display name for the Supabase project."
  type        = string
  default     = "adk-agents-vector-db"
}

variable "database_password" {
  description = "Password for the Supabase project's postgres user. Mark sensitive in HCP Terraform."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Supabase region. See https://supabase.com/docs/guides/platform/regions for valid values."
  type        = string
  default     = "us-east-1"
}
