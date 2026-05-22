output "service_account_email" {
  description = "Share your private Google Calendar with this address (Viewer role)."
  value       = google_service_account.daily_briefing.email
}

output "service_account_key_base64" {
  description = "Base64-encoded service account JSON key. Retrieve with: terraform output -raw service_account_key_base64"
  value       = google_service_account_key.daily_briefing.private_key
  sensitive   = true
}
