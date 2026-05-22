variable "project_id" {
  description = "ID of the existing GCP project to deploy into."
  type        = string
}

variable "region" {
  description = "Default GCP region."
  type        = string
  default     = "us-central1"
}
