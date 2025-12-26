module "nixos_server" {

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
      protocol   = "imcp"
      source_ips = ["0.0.0.0/0", "::/0"]
    }
  ]
  
  source = "../.."

  enable_backups            = true
  enable_delete_protection  = true
  
  flake_path = "./nix"

  hetzner_cloud_token = var.hetzner_cloud_token
  host_name           = "complete-server"

  labels = {
    environment = "example"
    project     = "terraform-hetzner-nixos"
    example     = "complete"
  }
  
  location    = "nbg1"

  server_type = "cx21"

  ssh_public_key_path = "~/.ssh/id_ed25519.pub"
  ssh_private_key_path = "~/.ssh/id_ed25519"
  
  volume_mount_point = "/var/lib/data"
  volume_size        = 20
  
}
