provider "google" {
  project = var.project_id
  user_project_override = true
  billing_project = var.project_id
}

resource "random_string" "bucket_name" {
  length           = 8
  special          = false
  upper            = false
}

module "bucket" {
  source     = "../.."
  project_id = var.project_id
  name       = random_string.bucket_name.result
}