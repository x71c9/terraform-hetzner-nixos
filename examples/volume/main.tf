module "nixos_server" {

  source = "../.."

  hetzner_cloud_token = var.hetzner_cloud_token
  host_name           = "server-with-volume"

  ssh_public_key_path = "/home/x71c9/.ssh/id_a15-ios-iph.pub"
  ssh_private_key_path = "/home/x71c9/.ssh/id_a15-ios-iph"
  
  volume_mount_point = "/var/lib/data"
  volume_size        = 20
  
}

output "server_ip" {
  description = "The IP address of the NixOS server"
  value       = module.nixos_server.server_ip
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh -i <private_key_path> root@${module.nixos_server.server_ip}"
}

output "volume_id" {
  description = "The ID of the volume"
  value       = module.nixos_server.volume_id
}
