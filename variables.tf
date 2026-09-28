variable "additional_firewall_rules" {
  description = "Additional firewall rules (SSH 22 is controlled by enable_ssh_rule)"
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

variable "enable_server_delete_protection" {
  description = "Enable delete protection for the server (recommended for production)"
  type        = bool
  default     = false
}

variable "enable_ssh_rule" {
  description = "Allow public SSH (tcp 22) in the Hetzner firewall. Required while installing or reinstalling the server over SSH; set to false for hosts reached only through a VPN."
  type        = bool
  default     = true
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

variable "ssh_key_ids" {
  description = "List of SSH key IDs to attach to the server. If empty, a new key will be created from ssh_public_key_path"
  type        = list(string)
  default     = []
}

variable "ssh_public_key_path" {
  description = "SSH public key file path for accessing the server (only used if ssh_key_ids is empty)"
  type        = string
  default     = null
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

variable "enable_volume_delete_protection" {
  description = "Enable delete protection for the volume (recommended for production)"
  type        = bool
  default     = false
}

variable "download_nixos_config" {
  description = "Download NixOS configuration files to local nixos-config/ directory for easy nixos-rebuild usage"
  type        = bool
  default     = true
}

