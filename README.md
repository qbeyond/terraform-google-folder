<!-- BEGIN_TF_DOCS -->
## Usage

This Module creates a GCP Folder
```hcl
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
}
variable "project_id" {
  type = string
  description = "The Project ID where to create the Folder"
}

variable "organization_domain" {
  type = string
}
```

This Module creates a GCP Folder with a firewall policy
It is possible to include yaml config files.
```hcl
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
variable "project_id" {
  type = string
  description = "The Project ID where to create the Folder"
}

variable "organization_domain" {
  type = string
}
```

```yaml
rfc1918:
  - 10.0.0.0/8
  - 172.16.0.0/12
  - 192.168.0.0/16
allow-admins:
  description: Access from the admin subnet to all subnets
  direction: INGRESS
  action: allow
  priority: 1000
  ranges:
    - $rfc1918
  ports:
    all: []
  target_resources: null
  enable_logging: false

allow-ssh-from-iap:
  description: Enable SSH from IAP
  direction: INGRESS
  action: allow
  priority: 1002
  ranges:
    - 35.235.240.0/20
  ports:
    tcp: ["22"]
  target_resources: null
  enable_logging: false
```

This Module creates a GCP Folder with a hierarchical firewall policy
```hcl
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
variable "project_id" {
  type = string
  description = "The Project ID where to create the Folder"
}

variable "organization_domain" {
  type = string
}
```

This Module creates a GCP Folder with a iam policies
```hcl
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
variable "project_id" {
  type = string
  description = "The Project ID where to create the Folder"
}

variable "organization_domain" {
  type = string
}

variable "user_email" {
  type = string
  description = "Email of an existing GCP User"
}
```

This Module creates a GCP Folder with org policies
```hcl
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
variable "project_id" {
  type = string
  description = "The Project ID where to create the Folder"
}

variable "organization_domain" {
  type = string
}
```

This Module creates a GCP Folder with sink for logging
```hcl
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
variable "project_id" {
  type = string
  description = "The Project ID where to create the Folder"
}

variable "organization_domain" {
  type = string
}
```

This Module creates a GCP Folder with tags
```hcl
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
variable "project_id" {
  type = string
  description = "The Project ID where to create the Folder"
}

variable "organization_domain" {
  type = string
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.1 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.40.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.40.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_contacts"></a> [contacts](#input\_contacts) | List of essential contacts for this resource. Must be in the form EMAIL -> [NOTIFICATION\_TYPES]. Valid notification types are ALL, SUSPENSION, SECURITY, TECHNICAL, BILLING, LEGAL, PRODUCT\_UPDATES. | `map(list(string))` | `{}` | no |
| <a name="input_firewall_policies"></a> [firewall\_policies](#input\_firewall\_policies) | Hierarchical firewall policies created in this folder. | <pre>map(map(object({<br>    action                  = string<br>    description             = string<br>    direction               = string<br>    logging                 = bool<br>    ports                   = map(list(string))<br>    priority                = number<br>    ranges                  = list(string)<br>    target_resources        = list(string)<br>    target_service_accounts = list(string)<br>  })))</pre> | `{}` | no |
| <a name="input_firewall_policy_association"></a> [firewall\_policy\_association](#input\_firewall\_policy\_association) | The hierarchical firewall policy to associate to this folder. Must be either a key in the `firewall_policies` map or the id of a policy defined somewhere else. | `map(string)` | `{}` | no |
| <a name="input_firewall_policy_factory"></a> [firewall\_policy\_factory](#input\_firewall\_policy\_factory) | Configuration for the firewall policy factory. | <pre>object({<br>    cidr_file   = string<br>    policy_name = string<br>    rules_file  = string<br>  })</pre> | `null` | no |
| <a name="input_folder_create"></a> [folder\_create](#input\_folder\_create) | Create folder. When set to false, uses id to reference an existing folder. | `bool` | `true` | no |
| <a name="input_group_iam"></a> [group\_iam](#input\_group\_iam) | Authoritative IAM binding for organization groups, in {GROUP\_EMAIL => [ROLES]} format. Group emails need to be static. Can be used in combination with the `iam` variable. | `map(list(string))` | `{}` | no |
| <a name="input_iam"></a> [iam](#input\_iam) | IAM bindings in {ROLE => [MEMBERS]} format. | `map(list(string))` | `{}` | no |
| <a name="input_iam_additive"></a> [iam\_additive](#input\_iam\_additive) | Non authoritative IAM bindings, in {ROLE => [MEMBERS]} format. | `map(list(string))` | `{}` | no |
| <a name="input_iam_additive_members"></a> [iam\_additive\_members](#input\_iam\_additive\_members) | IAM additive bindings in {MEMBERS => [ROLE]} format. This might break if members are dynamic values. | `map(list(string))` | `{}` | no |
| <a name="input_id"></a> [id](#input\_id) | Folder ID in case you use folder\_create=false. | `string` | `null` | no |
| <a name="input_logging_exclusions"></a> [logging\_exclusions](#input\_logging\_exclusions) | Logging exclusions for this folder in the form {NAME -> FILTER}. | `map(string)` | `{}` | no |
| <a name="input_logging_sinks"></a> [logging\_sinks](#input\_logging\_sinks) | Logging sinks to create for the organization. | <pre>map(object({<br>    bq_partitioned_table = optional(bool)<br>    description          = optional(string)<br>    destination          = string<br>    disabled             = optional(bool, false)<br>    exclusions           = optional(map(string), {})<br>    filter               = string<br>    include_children     = optional(bool, true)<br>    type                 = string<br>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Folder name. | `string` | `null` | no |
| <a name="input_org_policies"></a> [org\_policies](#input\_org\_policies) | Organization policies applied to this folder keyed by policy name. | <pre>map(object({<br>    inherit_from_parent = optional(bool) # for list policies only.<br>    reset               = optional(bool)<br><br>    # default (unconditional) values<br>    allow = optional(object({<br>      all    = optional(bool)<br>      values = optional(list(string))<br>    }))<br>    deny = optional(object({<br>      all    = optional(bool)<br>      values = optional(list(string))<br>    }))<br>    enforce = optional(bool, true) # for boolean policies only.<br><br>    # conditional values<br>    rules = optional(list(object({<br>      allow = optional(object({<br>        all    = optional(bool)<br>        values = optional(list(string))<br>      }))<br>      deny = optional(object({<br>        all    = optional(bool)<br>        values = optional(list(string))<br>      }))<br>      enforce = optional(bool, true) # for boolean policies only.<br>      condition = object({<br>        description = optional(string)<br>        expression  = optional(string)<br>        location    = optional(string)<br>        title       = optional(string)<br>      })<br>    })), [])<br>  }))</pre> | `{}` | no |
| <a name="input_org_policies_data_path"></a> [org\_policies\_data\_path](#input\_org\_policies\_data\_path) | Path containing org policies in YAML format. | `string` | `null` | no |
| <a name="input_parent"></a> [parent](#input\_parent) | Parent in folders/folder\_id or organizations/org\_id format. | `string` | `null` | no |
| <a name="input_tag_bindings"></a> [tag\_bindings](#input\_tag\_bindings) | Tag bindings for this folder, in key => tag value id format. | `map(string)` | `null` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_firewall_policies"></a> [firewall\_policies](#output\_firewall\_policies) | Map of firewall policy resources created in this folder. |
| <a name="output_firewall_policy_id"></a> [firewall\_policy\_id](#output\_firewall\_policy\_id) | Map of firewall policy ids created in this folder. |
| <a name="output_folder"></a> [folder](#output\_folder) | Folder resource. |
| <a name="output_id"></a> [id](#output\_id) | Folder id. |
| <a name="output_name"></a> [name](#output\_name) | Folder name. |
| <a name="output_sink_writer_identities"></a> [sink\_writer\_identities](#output\_sink\_writer\_identities) | Writer identities created for each sink. |

## Resource types
| Type | Used |
|------|-------|
| [google-beta_google_essential_contacts_contact](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_essential_contacts_contact) | 1 |
| [google_bigquery_dataset_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_iam_member) | 1 |
| [google_compute_firewall_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy) | 1 |
| [google_compute_firewall_policy_association](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_association) | 1 |
| [google_compute_firewall_policy_rule](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_rule) | 1 |
| [google_folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | 1 |
| [google_folder_iam_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_binding) | 1 |
| [google_folder_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | 1 |
| [google_logging_folder_exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_folder_exclusion) | 1 |
| [google_logging_folder_sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_folder_sink) | 1 |
| [google_org_policy_policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | 1 |
| [google_project_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | 1 |
| [google_pubsub_topic_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | 1 |
| [google_storage_bucket_iam_member](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | 1 |
| [google_tags_tag_binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_binding) | 1 |
**`Used` only includes resource blocks.** `for_each` and `count` meta arguments, as well as resource blocks of modules are not considered.

## Modules

No modules.

## Resources by Files
### firewall-policies.tf
| Name | Type |
|------|------|
| [google_compute_firewall_policy.policy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy) | resource |
| [google_compute_firewall_policy_association.association](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_association) | resource |
| [google_compute_firewall_policy_rule.rule](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall_policy_rule) | resource |
### iam.tf
| Name | Type |
|------|------|
| [google_folder_iam_binding.authoritative](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_binding) | resource |
| [google_folder_iam_member.additive](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
### logging.tf
| Name | Type |
|------|------|
| [google_bigquery_dataset_iam_member.bq-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset_iam_member) | resource |
| [google_logging_folder_exclusion.logging-exclusion](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_folder_exclusion) | resource |
| [google_logging_folder_sink.sink](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/logging_folder_sink) | resource |
| [google_project_iam_member.bucket-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_pubsub_topic_iam_member.pubsub-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_storage_bucket_iam_member.gcs-sinks-binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
### main.tf
| Name | Type |
|------|------|
| [google-beta_google_essential_contacts_contact.contact](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_essential_contacts_contact) | resource |
| [google_folder.folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_folder.folder](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/folder) | data source |
### organization-policies.tf
| Name | Type |
|------|------|
| [google_org_policy_policy.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/org_policy_policy) | resource |
### tags.tf
| Name | Type |
|------|------|
| [google_tags_tag_binding.binding](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/tags_tag_binding) | resource |
<!-- END_TF_DOCS -->