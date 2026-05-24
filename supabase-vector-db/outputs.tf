output "project_url" {
  description = "Supabase project URL. Use as SUPABASE_URL in ADK agent environments."
  value       = "https://${supabase_project.vector_db.id}.supabase.co"
}

output "anon_key" {
  description = "Supabase anon/public key (SUPABASE_ANON_KEY). Safe for client-side use; subject to row-level security."
  value       = supabase_project.vector_db.anon_key
  sensitive   = true
}

output "service_role_key" {
  description = "Supabase service role key (SUPABASE_SERVICE_ROLE_KEY). Full DB access — server-side only, never expose client-side."
  value       = supabase_project.vector_db.service_role_key
  sensitive   = true
}

output "database_url" {
  description = "Direct PostgreSQL connection string. Use for schema migrations and one-time setup."
  value       = "postgresql://postgres:${var.database_password}@db.${supabase_project.vector_db.id}.supabase.co:5432/postgres"
  sensitive   = true
}

output "project_ref" {
  description = "Supabase project reference ID (the subdomain slug)."
  value       = supabase_project.vector_db.id
}
