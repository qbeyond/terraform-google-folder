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

  org_policies = {
    "compute.disableGuestAttributesAccess" = {
      enforce = true
    }
    "constraints/compute.skipDefaultNetworkCreation" = {
      enforce = true
    }
    "iam.disableServiceAccountKeyCreation" = {
      enforce = true
    }
    "iam.disableServiceAccountKeyUpload" = {
      enforce = false
      rules = [
        {
          condition = {
            expression  = "resource.matchTagId(\"tagKeys/1234\", \"tagValues/1234\")"
            title       = "condition"
            description = "test condition"
            location    = "somewhere"
          }
          enforce = true
        }
      ]
    }
    "constraints/iam.allowedPolicyMemberDomains" = {
      allow = {
        values = ["C0xxxxxxx", "C0yyyyyyy"]
      }
    }
    "constraints/compute.trustedImageProjects" = {
      allow = {
        values = ["projects/my-project"]
      }
    }
    "constraints/compute.vmExternalIpAccess" = {
      deny = { all = true }
    }
  }
}