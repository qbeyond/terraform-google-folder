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

resource "google_tags_tag_key" "default" {
  parent = data.google_organization.default.id
  short_name = "keyname"
  description = "For keyname resources."
}

resource "google_tags_tag_value" "default" {
    parent = google_tags_tag_key.default.id
    short_name = "valuename"
    description = "For valuename resources."
}

module "folder" {
  source = "../.."
  parent = data.google_organization.default.id
  name   = random_string.folder_name.result

  tag_bindings = {
    foo      = google_tags_tag_value.default.id
  }
}