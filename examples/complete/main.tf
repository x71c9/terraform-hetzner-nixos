terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

provider "hcloud" {
  token = var.hetzner_cloud_token
}

module "nixos_server" {
  source = "../.."

  additional_firewall_rules = [
    {
      direction  = "in"
      port       = "80"
      protocol   = "tcp"
      source_ips = ["0.0.0.0/0", "::/0"]
    },
    {
      direction  = "in"
      port       = "443"
      protocol   = "tcp"
      source_ips = ["0.0.0.0/0", "::/0"]
    },
    {
      direction  = "in"
      protocol   = "icmp"
      source_ips = ["0.0.0.0/0", "::/0"]
    }
  ]
  
  enable_backups            = true
  enable_delete_protection  = false


  hetzner_cloud_token = var.hetzner_cloud_token
  host_name           = "complete-server"

  labels = {
    environment = "example"
    project     = "terraform-hetzner-nixos"
    example     = "complete"
  }
  
  location = "nbg1"

  server_type = "cx33"

  ssh_private_key_path = var.ssh_private_key_path
  ssh_public_key_path  = var.ssh_public_key_path
  
  volume_mount_point = "/var/lib/data"
  volume_size        = 21
}

