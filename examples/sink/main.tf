provider "google" {
  project = var.project_id
  user_project_override = true
  billing_project = var.project_id
}

resource "random_string" "folder_name" {
  length           = 8
  special          = false
  upper            = false
  numeric          = false
}

resource "random_string" "bucket_name" {
  length           = 8
  special          = false
  upper            = false
  numeric          = false
}

data "google_organization" "default" {
  domain = var.organization_domain
}

resource "google_storage_bucket" "logging" {
  name          = random_string.bucket_name.result
  project       = var.project_id
  location      = "EU"
  force_destroy = true
}

module "folder-sink" {
  source = "../.."
  parent = data.google_organization.default.id
  name   = random_string.folder_name.result

  logging_sinks = {
    "info" = {
      bq_partitioned_table = false
      description = "This is sending info logs to the bucket"
      destination = google_storage_bucket.logging.id
      disabled = false
      exclusions = {
        "key" = "value"
      }
      filter = "severity=INFO"
      include_children = true
      type = "storage"
    }
  }
}