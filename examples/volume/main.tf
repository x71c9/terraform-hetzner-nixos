terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

# Authentication: Set HCLOUD_TOKEN environment variable or configure the provider with a token
# export HCLOUD_TOKEN="your-token-here"
provider "hcloud" {
  # token = var.hetzner_cloud_token  # Optional: use variable instead of env var
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


module "nixos_server" {
  source = "../.."
  host_name           = "server-with-volume"
  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path
  volume_mount_point = "/var/lib/data"
  volume_size        = 20
}

output "server_ip" {
  description = "The IP address of the NixOS server"
  value       = module.nixos_server.server_ip
}

output "volume_id" {
  description = "The ID of the volume"
  value       = module.nixos_server.volume_id
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = var.ssh_private_key_path != "" ? "\n\nssh -i ${var.ssh_private_key_path} root@${module.nixos_server.server_ip}\n\n" : "\n\nssh root@${module.nixos_server.server_ip}\n\n"
}

