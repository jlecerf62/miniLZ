locals {
  secure_vcn_display_name = "secure-vcn"
  secure_vcn_dns_label    = "secvcn"

  lb_subnet_display_name = "lb-subnet"
  lb_subnet_dns_label    = "lbsub"

  app_subnet_display_name = "app-subnet"
  app_subnet_dns_label    = "appsub"

  db_subnet_display_name = "db-subnet"
  db_subnet_dns_label    = "dbsub"

  # RFC1918 prefixes routed to DRG on all 3 route tables
  rfc1918 = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]
}

# Secure VCN in secured compartment (CIDR as variable)
resource "oci_core_vcn" "secure_vcn" {
  compartment_id = oci_identity_compartment.secure_compartment.id
  cidr_blocks    = var.secure_vcn_cidr_blocks
  display_name   = local.secure_vcn_display_name
  dns_label      = local.secure_vcn_dns_label
}

# DRG and attachment to VCN
resource "oci_core_drg" "secure_drg" {
  compartment_id = oci_identity_compartment.secure_compartment.id
  display_name   = "secure-drg"
}

resource "oci_core_drg_attachment" "secure_vcn_to_drg" {
  drg_id       = oci_core_drg.secure_drg.id
  vcn_id       = oci_core_vcn.secure_vcn.id
  display_name = "secure-vcn-attachment"
}

# Service Gateway for Oracle Services Network
resource "oci_core_service_gateway" "secure_sgw" {
  compartment_id = oci_identity_compartment.secure_compartment.id
  vcn_id         = oci_core_vcn.secure_vcn.id
  display_name   = "secure-svc-gw"

  services {
    service_id = data.oci_core_services.all_oci_services.services[0].id
  }
}

# NAT Gateway (for app-subnet default egress)
resource "oci_core_nat_gateway" "secure_nat" {
  compartment_id = oci_identity_compartment.secure_compartment.id
  vcn_id         = oci_core_vcn.secure_vcn.id
  display_name   = "secure-nat"
  block_traffic  = false
}

# Route table for lb-subnet: RFC1918 -> DRG, OSN -> Service Gateway
resource "oci_core_route_table" "lb_rt" {
  compartment_id = oci_identity_compartment.secure_compartment.id
  vcn_id         = oci_core_vcn.secure_vcn.id
  display_name   = "lb-rt"

  dynamic "route_rules" {
    for_each = var.ipsec_enabled ? var.ipsec_onprem_cidrs : []
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_drg.secure_drg.id
      description       = "On-prem to DRG"
    }
  }

  route_rules {
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.secure_sgw.id
    description       = "OSN via Service Gateway"
  }
}

# Route table for app-subnet: RFC1918 -> DRG, OSN -> SGW, Default -> NAT
resource "oci_core_route_table" "app_rt" {
  compartment_id = oci_identity_compartment.secure_compartment.id
  vcn_id         = oci_core_vcn.secure_vcn.id
  display_name   = "app-rt"

  dynamic "route_rules" {
    for_each = var.ipsec_enabled ? var.ipsec_onprem_cidrs : []
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_drg.secure_drg.id
      description       = "On-prem to DRG"
    }
  }

  route_rules {
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.secure_sgw.id
    description       = "OSN via Service Gateway"
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.secure_nat.id
    description       = "Default egress via NAT"
  }
}

# Route table for db-subnet: RFC1918 -> DRG, OSN -> Service Gateway
resource "oci_core_route_table" "db_rt" {
  compartment_id = oci_identity_compartment.secure_compartment.id
  vcn_id         = oci_core_vcn.secure_vcn.id
  display_name   = "db-rt"

  dynamic "route_rules" {
    for_each = var.ipsec_enabled ? var.ipsec_onprem_cidrs : []
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_drg.secure_drg.id
      description       = "On-prem to DRG"
    }
  }

  route_rules {
    destination       = data.oci_core_services.all_oci_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.secure_sgw.id
    description       = "OSN via Service Gateway"
  }
}

# Private subnets with dedicated route tables
resource "oci_core_subnet" "lb_subnet" {
  compartment_id             = oci_identity_compartment.secure_compartment.id
  vcn_id                     = oci_core_vcn.secure_vcn.id
  cidr_block                 = var.lb_subnet_cidr
  display_name               = local.lb_subnet_display_name
  dns_label                  = local.lb_subnet_dns_label
  route_table_id             = oci_core_route_table.lb_rt.id
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "app_subnet" {
  compartment_id             = oci_identity_compartment.secure_compartment.id
  vcn_id                     = oci_core_vcn.secure_vcn.id
  cidr_block                 = var.app_subnet_cidr
  display_name               = local.app_subnet_display_name
  dns_label                  = local.app_subnet_dns_label
  route_table_id             = oci_core_route_table.app_rt.id
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "db_subnet" {
  compartment_id             = oci_identity_compartment.secure_compartment.id
  vcn_id                     = oci_core_vcn.secure_vcn.id
  cidr_block                 = var.db_subnet_cidr
  display_name               = local.db_subnet_display_name
  dns_label                  = local.db_subnet_dns_label
  route_table_id             = oci_core_route_table.db_rt.id
  prohibit_internet_ingress  = true
  prohibit_public_ip_on_vnic = true
}

# Outputs
output "secure_vcn_id" {
  value = oci_core_vcn.secure_vcn.id
}

output "secure_drg_id" {
  value = oci_core_drg.secure_drg.id
}

output "secure_service_gateway_id" {
  value = oci_core_service_gateway.secure_sgw.id
}

output "secure_nat_gateway_id" {
  value = oci_core_nat_gateway.secure_nat.id
}

output "lb_subnet_id" {
  value = oci_core_subnet.lb_subnet.id
}

output "app_subnet_id" {
  value = oci_core_subnet.app_subnet.id
}

output "db_subnet_id" {
  value = oci_core_subnet.db_subnet.id
}

output "lb_route_table_id" {
  value = oci_core_route_table.lb_rt.id
}

output "app_route_table_id" {
  value = oci_core_route_table.app_rt.id
}

output "db_route_table_id" {
  value = oci_core_route_table.db_rt.id
}
