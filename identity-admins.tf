# Identity Admins: Create users in default Identity Domain, add to Administrators group

# Discover the default Identity Domain in the tenancy (root compartment)
data "oci_identity_domains" "default" {
  compartment_id = var.tenancy_ocid
  type           = "DEFAULT"
}

# Endpoint for Identity Domains (IDCS) API - required by oci_identity_domains_user
locals {
  idcs_endpoint = data.oci_identity_domains.default.domains[0].url
}

# Create Identity Domain users from input list
resource "oci_identity_domains_user" "admins" {
  for_each      = toset(var.admin_users)
  idcs_endpoint = local.idcs_endpoint

  # Required by SCIM - base User schema
  schemas   = ["urn:ietf:params:scim:schemas:core:2.0:User"]
  user_name = each.value

  description = "Admin user"
  name {
    family_name = each.value
  }
  # Primary work email (recommended to set)
  emails {
    type    = "work"
    value   = each.value
    primary = true
  }

  # Recovery email (provider recommends setting this; will default to primary if omitted)
  emails {
    type  = "recovery"
    value = each.value
  }
}

# Lookup classic IAM "Administrators" group in the tenancy
data "oci_identity_groups" "administrators" {
  compartment_id = var.tenancy_ocid
  filter {
    name   = "name"
    values = ["Administrators"]
  }
}

# Add each newly created domain user (by OCID) to classic IAM Administrators group
resource "oci_identity_user_group_membership" "admins" {
  for_each = oci_identity_domains_user.admins

  group_id = data.oci_identity_groups.administrators.groups[0].id
  user_id  = each.value.ocid
}
