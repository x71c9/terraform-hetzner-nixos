variable "additional_firewall_rules" {
  description = "Additional firewall rules beyond SSH (22)"
  type = list(object({
    direction  = string
    port       = optional(string)
    protocol   = string
    source_ips = list(string)
  }))
  default = []
}

variable "enable_backups" {
  description = "Enable automatic backups"
  type        = bool
  default     = false
}

variable "enable_delete_protection" {
  description = "Enable delete protection (recommended for production)"
  type        = bool
  default     = false
}


variable "hetzner_cloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "host_name" {
  description = "Host configuration name"
  type        = string
}

variable "labels" {
  description = "Additional labels for the server"
  type        = map(string)
  default     = {}
}

#########################
# Server location
# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server#location-1
#########################
variable "location" {
  description = "Hetzner Cloud location"
  type        = string
  default     = "nbg1"
}

#########################
# Server type
# https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server#server_type-1
#########################
variable "server_type" {
  description = "Hetzner Cloud server type"
  type        = string
  default     = "cx23"
}

variable "ssh_public_key_path" {
  description = "SSH public key file path for accessing the server"
  type        = string
}

variable "ssh_private_key_path" {
  description = "SSH private key file path for accessing the server"
  type        = string
  default     = ""
}

variable "volume_size" {
  description = "Size of the additional volume in GB (optional)"
  type        = number
  default     = null
}

variable "volume_mount_point" {
  description = "Mount point for the additional volume (only used if volume_size is set)"
  type        = string
  default     = "/mnt/data"
}

variable "download_nixos_config" {
  description = "Download NixOS configuration files to local nixos-config/ directory for easy nixos-rebuild usage"
  type        = bool
  default     = true
}

