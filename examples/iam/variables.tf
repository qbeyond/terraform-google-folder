variable "billing_project_id" {
  type = string
  description = "The Project ID to use for billing."
}

variable "organization_domain" {
  type = string
}

variable "user_email" {
  type = string
  description = "Email of an existing GCP User"
}