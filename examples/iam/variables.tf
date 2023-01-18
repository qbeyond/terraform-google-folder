variable "project_id" {
  type = string
  description = "The Project ID where to create the GCS Bucket"
}

variable "organization_domain" {
  type = string
}

variable "user_email" {
  type = string
  description = "Email of an existing GCP User"
}