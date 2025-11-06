variable "tenancy_ocid" {
  description = "tenancy_ocid"
  type        = string
}

variable "user_ocid" {
  description = "user_ocid"
  type        = string
}

variable "fingerprint" {
  description = "fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "private_key_path"
  type        = string
}

variable "region" {
  description = "tenancy_ocid"
  type        = string
}

variable "secure_vcn_cidr_blocks" {
  description = "CIDR blocks for the secure VCN"
  type        = list(string)
}

variable "lb_subnet_cidr" {
  description = "CIDR for the load balancer subnet"
  type        = string
}

variable "app_subnet_cidr" {
  description = "CIDR for the application subnet"
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR for the database subnet"
  type        = string
}

############################################
# IPSec / VPN variables
############################################

variable "ipsec_enabled" {
  description = "Enable creation of IPSec site-to-site VPN resources (CPE, IPsec connection, tunnel settings). When false, resources are skipped and route rules are not added."
  type        = bool
  default     = false
}

variable "ipsec_cpe_public_ip" {
  description = "Public IP address of the on-premises VPN device (CPE). Optional when ipsec_enabled is false."
  type        = string
  default     = null
  validation {
    condition     = var.ipsec_enabled ? (var.ipsec_cpe_public_ip != null && can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.ipsec_cpe_public_ip))) : true
    error_message = "When ipsec_enabled is true, ipsec_cpe_public_ip must be set to a valid IPv4 address."
  }
}

variable "ipsec_cpe_display_name" {
  description = "Display name for the CPE object."
  type        = string
  default     = "onprem-cpe"
}

variable "ipsec_display_name" {
  description = "Display name for the IPSec site-to-site connection."
  type        = string
  default     = "site-to-site-ipsec"
}

variable "ipsec_routing_type" {
  description = "Routing type for the IPsec tunnel. Default STATIC. You may also use POLICY (policy-based) or BGP."
  type        = string
  default     = "STATIC"
  validation {
    condition     = contains(["STATIC", "POLICY", "BGP"], var.ipsec_routing_type)
    error_message = "ipsec_routing_type must be one of: STATIC, POLICY, BGP"
  }
}

variable "ipsec_onprem_cidrs" {
  description = "List of on-premises CIDR prefixes to route to the DRG (used for both STATIC routes and VCN route tables)."
  type        = list(string)
  default     = []
}

# Policy-based traffic selectors
variable "ipsec_policy_based_enabled" {
  description = "Enable policy-based traffic selectors on the IPsec tunnels."
  type        = bool
  default     = false
}

variable "ipsec_policy_local_selectors" {
  description = "Local (VCN) CIDR selectors for policy-based tunnels."
  type        = list(string)
  default     = []
}

variable "ipsec_policy_remote_selectors" {
  description = "Remote (on-prem) CIDR selectors for policy-based tunnels."
  type        = list(string)
  default     = []
}

# Tunnel parameters (with defaults)
variable "ipsec_ike_version" {
  description = "IKE version for tunnels."
  type        = string
  default     = "V2"
  validation {
    condition     = contains(["V1", "V2"], var.ipsec_ike_version)
    error_message = "ipsec_ike_version must be V1 or V2"
  }
}

variable "ipsec_nat_t_setting" {
  description = "NAT-T setting for tunnels (ENABLED, DISABLED, or AUTO)."
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED", "AUTO"], var.ipsec_nat_t_setting)
    error_message = "ipsec_nat_t_setting must be one of: ENABLED, DISABLED, AUTO"
  }
}

variable "ipsec_dpd_timeout_in_seconds" {
  description = "DPD timeout in seconds for tunnels."
  type        = number
  default     = 30
}

# Phase 1 (IKE) parameters
variable "ipsec_phase1_encryption_algorithms" {
  description = "Phase 1 (IKE) encryption algorithms."
  type        = list(string)
  default     = ["AES_256_CBC"]
}

variable "ipsec_phase1_authentication_algorithms" {
  description = "Phase 1 (IKE) authentication algorithms."
  type        = list(string)
  default     = ["SHA2_384"]
}

variable "ipsec_phase1_dh_groups" {
  description = "Phase 1 (IKE) DH groups."
  type        = list(string)
  default     = ["GROUP20"]
}

variable "ipsec_phase1_lifetime_in_seconds" {
  description = "Phase 1 (IKE) SA lifetime in seconds."
  type        = number
  default     = 28800
}

# Phase 2 (IPSec) parameters
variable "ipsec_phase2_encryption_algorithms" {
  description = "Phase 2 (IPSec) encryption algorithms."
  type        = list(string)
  default     = ["AES_256_GCM"]
}

variable "ipsec_phase2_authentication_algorithms" {
  description = "Phase 2 (IPSec) authentication algorithms."
  type        = list(string)
  default     = ["HMAC_SHA2_256_128"]
}

variable "ipsec_phase2_pfs_dh_groups" {
  description = "Phase 2 (IPSec) PFS DH groups."
  type        = list(string)
  default     = ["GROUP5"]
}

variable "ipsec_phase2_lifetime_in_seconds" {
  description = "Phase 2 (IPSec) SA lifetime in seconds."
  type        = number
  default     = 3600
}

# Pre-shared keys (optional; if set, will be applied to the tunnels)
variable "ipsec_tunnel1_psk" {
  description = "Pre-shared key for tunnel 1 (optional)."
  type        = string
  default     = null
  sensitive   = true
}

variable "ipsec_tunnel2_psk" {
  description = "Pre-shared key for tunnel 2 (optional)."
  type        = string
  default     = null
  sensitive   = true
}
