terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.44"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_cloud_token
}

variable "hetzner_cloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
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
  hetzner_cloud_token  = var.hetzner_cloud_token
  ssh_public_key_path  = var.ssh_public_key_path
  ssh_private_key_path = var.ssh_private_key_path
  host_name            = "nixos-server"
}

output "server_ip" {
  description = "The IP address of the NixOS server"
  value       = module.nixos_server.server_ip
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = var.ssh_private_key_path != "" ? "\n\nssh -i ${var.ssh_private_key_path} root@${module.nixos_server.server_ip}\n\n" : "\n\nssh root@${module.nixos_server.server_ip}\n\n"
}
