locals {
  public_vcn_cidr_blocks     = ["10.0.0.0/16"]
  public_subnet_cidr         = "10.0.1.0/24"
  public_vcn_display_name    = "public-vcn"
  public_vcn_dns_label       = "pubvcn"
  public_subnet_display_name = "public-subnet"
  public_subnet_dns_label    = "pubsub"
}

# Public VCN in non-secured compartment
resource "oci_core_vcn" "public_vcn" {
  compartment_id = oci_identity_compartment.unsecure_compartment.id
  cidr_blocks    = local.public_vcn_cidr_blocks
  display_name   = local.public_vcn_display_name
  dns_label      = local.public_vcn_dns_label
}

# Internet Gateway
resource "oci_core_internet_gateway" "public_igw" {
  compartment_id = oci_identity_compartment.unsecure_compartment.id
  vcn_id         = oci_core_vcn.public_vcn.id
  display_name   = "public-igw"
  enabled        = true
}

# Route table with default route to IGW
resource "oci_core_route_table" "public_rt" {
  compartment_id = oci_identity_compartment.unsecure_compartment.id
  vcn_id         = oci_core_vcn.public_vcn.id
  display_name   = "public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.public_igw.id
    description       = "Default route to Internet"
  }
}

# Basic public security list (SSH + ICMP; allow all egress)
resource "oci_core_security_list" "public_sl" {
  compartment_id = oci_identity_compartment.unsecure_compartment.id
  vcn_id         = oci_core_vcn.public_vcn.id
  display_name   = "public-security-list"

  # Allow all egress
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
    description = "Allow all egress"
  }

  # Allow SSH from anywhere
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "6" # TCP
    stateless   = false
    description = "Allow SSH from Internet"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow ICMP fragmentation-needed for PMTU discovery
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "1" # ICMP
    stateless   = false
    description = "Allow ICMP type 3 code 4 (fragmentation needed)"
    icmp_options {
      type = 3
      code = 4
    }
  }

  # Allow ICMP echo (ping)
  ingress_security_rules {
    source      = "0.0.0.0/0"
    protocol    = "1" # ICMP
    stateless   = false
    description = "Allow ICMP echo (ping)"
    icmp_options {
      type = 8
    }
  }
}

# Public subnet (/24) associated to the public route table and security list
resource "oci_core_subnet" "public_subnet" {
  compartment_id             = oci_identity_compartment.unsecure_compartment.id
  vcn_id                     = oci_core_vcn.public_vcn.id
  cidr_block                 = local.public_subnet_cidr
  display_name               = local.public_subnet_display_name
  dns_label                  = local.public_subnet_dns_label
  route_table_id             = oci_core_route_table.public_rt.id
  security_list_ids          = [oci_core_security_list.public_sl.id]
  prohibit_internet_ingress  = false
  prohibit_public_ip_on_vnic = false
}

# Outputs
output "public_vcn_id" {
  value = oci_core_vcn.public_vcn.id
}

output "public_igw_id" {
  value = oci_core_internet_gateway.public_igw.id
}

output "public_route_table_id" {
  value = oci_core_route_table.public_rt.id
}

output "public_subnet_id" {
  value = oci_core_subnet.public_subnet.id
}

output "public_subnet_cidr" {
  value = oci_core_subnet.public_subnet.cidr_block
}
