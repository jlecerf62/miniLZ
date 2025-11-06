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
