# miniLZ – OCI Networking with IPSec VPN

This Terraform stack provisions:

- Compartments (secured and non-secured)
- Public VCN with Internet Gateway
- Secure VCN with DRG, DRG attachment, NAT Gateway, Service Gateway
- Three private subnets (LB/App/DB) with appropriate route tables
- IPSec Site-to-Site VPN (CPE, IPsec connection, per-tunnel management) with most parameters exposed as variables
- Default routing mode: STATIC, with option to use POLICY-based selectors (and room to extend to BGP)

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/jlecerf62/miniLZ/releases/download/latest/miniLZ.zip)

## Topology

![Topology](Topology.png)

The IPSec tunnels terminate on Oracle VPN headends (exported as outputs) and the DRG is attached to the secure VCN. Route tables in the secure VCN direct only on‑prem prefixes (from `ipsec_onprem_cidrs`) to the DRG.

## Prerequisites

- Terraform >= 1.3
- OCI credentials with permissions to create networking resources:
  - tenancy_ocid, user_ocid, fingerprint, private_key_path, region
- An on‑premises VPN device public IP (for the CPE) if enabling IPSec

## Quick start

1) Initialize

   ```bash
   terraform init
   ```

2) Configure variables
   - Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in authentication and network CIDRs.
   - IPSec is optional and disabled by default. To enable, add or uncomment lines like:

   ```hcl
   # IPSec (STATIC example)
   ipsec_enabled       = true
   ipsec_cpe_public_ip = "203.0.113.10"
   ipsec_onprem_cidrs  = ["192.168.10.0/24", "172.16.50.0/24"]
   ipsec_routing_type  = "STATIC" # or "POLICY"
   ```

   Policy‑based (encryption domain) example:

   ```hcl
   ipsec_enabled                 = true
   ipsec_cpe_public_ip           = "203.0.113.10"
   ipsec_routing_type            = "POLICY"
   ipsec_policy_based_enabled    = true
   ipsec_policy_local_selectors  = ["10.0.2.0/24", "10.0.3.0/24"]
   ipsec_policy_remote_selectors = ["192.168.10.0/24"]
   ```

   Optional tunnel crypto and PSKs can be overridden as needed (see Variable Reference).

3) Plan and apply

   ```bash
   terraform plan
   terraform apply
   ```

4) Check outputs

   ```bash
   terraform output
   terraform output ipsec_tunnel1_vpn_ip
   terraform output ipsec_tunnel2_vpn_ip
   terraform output ipsec_vpn_endpoints
   ```

## Variable reference (high level)

Authentication (provider.tf expects these in tfvars):

- user_ocid (string)
- fingerprint (string)
- private_key_path (string)
- region (string)
- tenancy_ocid (string)

Deployment scope:

- deployment_compartment_ocid (string, optional) — if set, the stack creates its child compartments (secured/non-secured) and the Cloud Guard security recipe under this parent compartment. If unset, it defaults to tenancy_ocid (root-level deployment).

Network CIDRs:

- secure_vcn_cidr_blocks (list(string))
- lb_subnet_cidr (string)
- app_subnet_cidr (string)
- db_subnet_cidr (string)

IPSec core:

- ipsec_enabled (bool, default false)
- ipsec_cpe_public_ip (string, default null; required only when `ipsec_enabled = true`)
- ipsec_cpe_display_name (string, default "onprem-cpe")
- ipsec_display_name (string, default "site-to-site-ipsec")

Routing:

- ipsec_routing_type (string: "STATIC" | "POLICY" | "BGP"; default "STATIC")
- ipsec_onprem_cidrs (list(string), default []) — used for static routes and VCN routing

Policy-based selectors (used when `ipsec_routing_type = "POLICY"` or `ipsec_policy_based_enabled = true`):

- ipsec_policy_based_enabled (bool, default false)
- ipsec_policy_local_selectors (list(string), default [])
- ipsec_policy_remote_selectors (list(string), default [])

Tunnel parameters (defaults provided; override as needed):

- ipsec_ike_version ("V1" | "V2", default "V2")
- ipsec_nat_t_setting ("AUTO" | "ENABLED" | "DISABLED", default "ENABLED")
- ipsec_dpd_timeout_in_seconds (number, default 30)

Phase 1 (IKE):

- ipsec_phase1_encryption_algorithms (list(string), default ["AES_256_CBC"])
- ipsec_phase1_authentication_algorithms (list(string), default ["SHA2_384"])
- ipsec_phase1_dh_groups (list(string), default ["GROUP20"])
- ipsec_phase1_lifetime_in_seconds (number, default 28800)

Phase 2 (IPsec):

- ipsec_phase2_encryption_algorithms (list(string), default ["AES_256_GCM"])
- ipsec_phase2_authentication_algorithms (list(string), default ["HMAC_SHA2_256_128"])
- ipsec_phase2_pfs_dh_groups (list(string), default ["GROUP5"])
- ipsec_phase2_lifetime_in_seconds (number, default 3600)

PSKs (optional):

- ipsec_tunnel1_psk (string, sensitive, default null)
- ipsec_tunnel2_psk (string, sensitive, default null)

Conditional requirements:

- When `ipsec_enabled = false`, IPSec variables are ignored and no IPSec resources are created.
- When `ipsec_enabled = true` and `ipsec_routing_type = "STATIC"`, set `ipsec_onprem_cidrs` to the remote prefixes to route.
- When `ipsec_enabled = true` and `ipsec_routing_type = "POLICY"`, set `ipsec_policy_local_selectors` and `ipsec_policy_remote_selectors`.

## Outputs

General networking:

- public_vcn_id, public_igw_id, public_route_table_id, public_subnet_id, public_subnet_cidr
- secure_vcn_id, secure_drg_id, secure_service_gateway_id, secure_nat_gateway_id
- lb_subnet_id, app_subnet_id, db_subnet_id
- lb_route_table_id, app_route_table_id, db_route_table_id

IPSec specific:

- ipsec_cpe_id
- ipsec_connection_id
- ipsec_tunnel_ids (list)
- ipsec_tunnel1_vpn_ip (Oracle VPN headend for tunnel 1)
- ipsec_tunnel2_vpn_ip (Oracle VPN headend for tunnel 2)
- ipsec_vpn_endpoints (list of both headend IPs)

## Security considerations

- Private subnets are created without public IPs. Ensure Security Lists or NSGs allow the desired application ports from on‑prem networks.
- Keep PSKs in a secure secret manager or pass via environment/secure pipelines; avoid committing sensitive values.

## Notes

- DRG is already attached to the secure VCN. Route tables now target only the provided on‑prem prefixes.
- For BGP mode, additional variables/blocks for BGP session settings can be added similarly to the current pattern if/when required.
