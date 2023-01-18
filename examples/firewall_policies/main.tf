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

module "folder" {
  source = "../.."
  parent = data.google_organization.default.id
  name   = random_string.folder_name.result

  firewall_policy_factory = {
    cidr_file   = "configs/cidrs.yaml"
    policy_name = "test"
    rules_file  = "configs/rules.yaml"
  }
  firewall_policy_association = {
    factory-policy = module.folder.firewall_policy_id["test"]
  }
}