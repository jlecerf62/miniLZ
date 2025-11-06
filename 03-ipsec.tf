# IPSec Site-to-Site VPN resources

############################################
# CPE (on-prem gateway)
############################################
resource "oci_core_cpe" "onprem_cpe" {
  count          = var.ipsec_enabled ? 1 : 0
  compartment_id = oci_identity_compartment.secure_compartment.id
  ip_address     = var.ipsec_cpe_public_ip
  display_name   = var.ipsec_cpe_display_name
}

############################################
# IPSec connection (links CPE <-> DRG)
# Note: 'routing' is configured per-tunnel (in tunnel management),
# not on the connection itself. Static routes (if any) are set here.
############################################
resource "oci_core_ipsec" "site_to_site" {
  count          = var.ipsec_enabled ? 1 : 0
  compartment_id = oci_identity_compartment.secure_compartment.id
  cpe_id         = oci_core_cpe.onprem_cpe[0].id
  drg_id         = oci_core_drg.secure_drg.id
  display_name   = var.ipsec_display_name

  # If using STATIC routing, provide on-prem CIDR prefixes as static routes.
  # Leave empty for BGP routing (routing mode is set per tunnel).
  static_routes = var.ipsec_routing_type == "STATIC" ? var.ipsec_onprem_cidrs : []
}

############################################
# Tunnels (read back)
############################################
data "oci_core_ipsec_connection_tunnels" "this" {
  count    = var.ipsec_enabled ? 1 : 0
  ipsec_id = oci_core_ipsec.site_to_site[0].id
}

############################################
# Tunnel 1 management
############################################
resource "oci_core_ipsec_connection_tunnel_management" "tunnel1" {
  count     = var.ipsec_enabled ? 1 : 0
  ipsec_id  = oci_core_ipsec.site_to_site[0].id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.this[0].ip_sec_connection_tunnels[0].id

  routing                 = var.ipsec_routing_type
  ike_version             = var.ipsec_ike_version
  nat_translation_enabled = var.ipsec_nat_t_setting

  dpd_config {
    dpd_mode           = "INITIATE_AND_RESPOND"
    dpd_timeout_in_sec = var.ipsec_dpd_timeout_in_seconds
  }

  phase_one_details {
    is_custom_phase_one_config      = true
    lifetime                        = var.ipsec_phase1_lifetime_in_seconds
    custom_encryption_algorithm     = var.ipsec_phase1_encryption_algorithms[0]
    custom_authentication_algorithm = var.ipsec_phase1_authentication_algorithms[0]
    custom_dh_group                 = var.ipsec_phase1_dh_groups[0]
  }

  phase_two_details {
    is_custom_phase_two_config      = true
    lifetime                        = var.ipsec_phase2_lifetime_in_seconds
    is_pfs_enabled                  = true
    dh_group                        = var.ipsec_phase2_pfs_dh_groups[0]
    custom_encryption_algorithm     = var.ipsec_phase2_encryption_algorithms[0]
    custom_authentication_algorithm = var.ipsec_phase2_authentication_algorithms[0]
  }

  dynamic "encryption_domain_config" {
    for_each = (var.ipsec_routing_type == "POLICY" || var.ipsec_policy_based_enabled) ? [1] : []
    content {
      oracle_traffic_selector = var.ipsec_policy_local_selectors
      cpe_traffic_selector    = var.ipsec_policy_remote_selectors
    }
  }

  shared_secret = var.ipsec_tunnel1_psk
}

############################################
# Tunnel 2 management
############################################
resource "oci_core_ipsec_connection_tunnel_management" "tunnel2" {
  count     = var.ipsec_enabled ? 1 : 0
  ipsec_id  = oci_core_ipsec.site_to_site[0].id
  tunnel_id = data.oci_core_ipsec_connection_tunnels.this[0].ip_sec_connection_tunnels[1].id

  routing                 = var.ipsec_routing_type
  ike_version             = var.ipsec_ike_version
  nat_translation_enabled = var.ipsec_nat_t_setting

  dpd_config {
    dpd_mode           = "INITIATE_AND_RESPOND"
    dpd_timeout_in_sec = var.ipsec_dpd_timeout_in_seconds
  }

  phase_one_details {
    is_custom_phase_one_config      = true
    lifetime                        = var.ipsec_phase1_lifetime_in_seconds
    custom_encryption_algorithm     = var.ipsec_phase1_encryption_algorithms[0]
    custom_authentication_algorithm = var.ipsec_phase1_authentication_algorithms[0]
    custom_dh_group                 = var.ipsec_phase1_dh_groups[0]
  }

  phase_two_details {
    is_custom_phase_two_config      = true
    lifetime                        = var.ipsec_phase2_lifetime_in_seconds
    is_pfs_enabled                  = true
    dh_group                        = var.ipsec_phase2_pfs_dh_groups[0]
    custom_encryption_algorithm     = var.ipsec_phase2_encryption_algorithms[0]
    custom_authentication_algorithm = var.ipsec_phase2_authentication_algorithms[0]
  }

  dynamic "encryption_domain_config" {
    for_each = (var.ipsec_routing_type == "POLICY" || var.ipsec_policy_based_enabled) ? [1] : []
    content {
      oracle_traffic_selector = var.ipsec_policy_local_selectors
      cpe_traffic_selector    = var.ipsec_policy_remote_selectors
    }
  }

  shared_secret = var.ipsec_tunnel2_psk
}

############################################
# Outputs
############################################
output "ipsec_cpe_id" {
  description = "OCID of the created CPE"
  value       = var.ipsec_enabled ? oci_core_cpe.onprem_cpe[0].id : null
}

output "ipsec_connection_id" {
  description = "OCID of the IPSec connection"
  value       = var.ipsec_enabled ? oci_core_ipsec.site_to_site[0].id : null
}

output "ipsec_tunnel_ids" {
  description = "IDs of the two IPSec tunnels"
  value       = var.ipsec_enabled ? [for t in data.oci_core_ipsec_connection_tunnels.this[0].ip_sec_connection_tunnels : t.id] : []
}

# Oracle VPN headend endpoints (per tunnel and aggregated)
output "ipsec_tunnel1_vpn_ip" {
  description = "Oracle VPN headend IP for tunnel 1"
  value       = var.ipsec_enabled ? oci_core_ipsec_connection_tunnel_management.tunnel1[0].vpn_ip : null
}

output "ipsec_tunnel2_vpn_ip" {
  description = "Oracle VPN headend IP for tunnel 2"
  value       = var.ipsec_enabled ? oci_core_ipsec_connection_tunnel_management.tunnel2[0].vpn_ip : null
}

output "ipsec_vpn_endpoints" {
  description = "Oracle VPN headend IPs for both tunnels"
  value       = var.ipsec_enabled ? [oci_core_ipsec_connection_tunnel_management.tunnel1[0].vpn_ip, oci_core_ipsec_connection_tunnel_management.tunnel2[0].vpn_ip] : []
}
