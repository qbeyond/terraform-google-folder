provider "google" {
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

module "folder" {
  source = "../.."
  parent = data.google_organization.default.id
  name   = random_string.folder_name.result
}