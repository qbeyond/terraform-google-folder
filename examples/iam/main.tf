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

data "google_organization" "default" {
  domain = var.organization_domain
}

# It is necessary to have permissions on your organizations level.
# You can add permissions to your account via https://admin.google.com
resource "google_cloud_identity_group" "basic" {
  parent = "customers/${data.google_organization.default.directory_customer_id}"

  group_key {
      id = "folderiamtest@${data.google_organization.default.domain}"
  }

  labels = {
    "cloudidentity.googleapis.com/groups.discussion_forum" = ""
  }
}

module "folder" {
  source = "../.."
  parent = data.google_organization.default.id
  name   = random_string.folder_name.result

  #authorative
  group_iam = {
    "${google_cloud_identity_group.basic.group_key.0.id}" = [
      "roles/owner",
      "roles/resourcemanager.folderAdmin",
      "roles/resourcemanager.projectCreator"
    ]
  }

  # authorative
  iam = {
    "roles/owner" = ["user:${var.user_email}"]
  }

  # additive
  iam_additive = {
    "roles/compute.admin"  = ["user:${var.user_email}"]
    "roles/compute.viewer" = ["user:${var.user_email}"]
  }

  iam_additive_members = {
    "user:${var.user_email}" = ["roles/storage.admin"]
    "user:${var.user_email}" = ["roles/storage.objectViewer"]
  }
}