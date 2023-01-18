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

resource "random_string" "folder_name_two" {
  length           = 8
  special          = false
  upper            = false
  numeric          = false
}

data "google_organization" "default" {
  domain = var.organization_domain
}

module "folder1" {
  source = "../.."
  parent = data.google_organization.default.id
  name   = random_string.folder_name.result

  firewall_policies = {
    iap-policy = {
      allow-iap-ssh = {
        description             = "Always allow ssh from IAP"
        direction               = "INGRESS"
        action                  = "allow"
        priority                = 100
        ranges                  = ["35.235.240.0/20"]
        ports                   = { tcp = ["22"] }
        target_service_accounts = null
        target_resources        = null
        logging                 = false
      }
    }
  }
  firewall_policy_association = {
    iap-policy = "iap-policy"
  }
}

module "folder2" {
  source = "../.."
  parent = data.google_organization.default.id
  name   = random_string.folder_name_two.result
  firewall_policy_association = {
    iap-policy = module.folder1.firewall_policy_id["iap-policy"]
  }
}