output "firewall_name" {
  description = "The name of the firewall created"
  value       = module.nixos_server.firewall_name
}

output "server_id" {
  description = "The ID of the Hetzner Cloud server"
  value       = module.nixos_server.server_id
}

output "server_ip" {
  description = "The public IPv4 address of the server"
  value       = module.nixos_server.server_ip
}

output "server_ipv4" {
  description = "The public IPv4 address of the server (alias)"
  value       = module.nixos_server.server_ipv4_address
}

output "server_ipv6" {
  description = "The public IPv6 address of the server"
  value       = module.nixos_server.server_ipv6
}

output "server_name" {
  description = "The name of the server"
  value       = module.nixos_server.server_name
}

output "ssh_key_id" {
  description = "The ID of the SSH key created"
  value       = module.nixos_server.ssh_key_id
}

output "ssh_key_name" {
  description = "The name of the SSH key created"
  value       = module.nixos_server.ssh_key_name
}

output "volume_id" {
  description = "The ID of the volume (if created)"
  value       = module.nixos_server.volume_id
}

output "volume_name" {
  description = "The name of the volume (if created)"
  value       = module.nixos_server.volume_name
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = var.ssh_private_key_path != "" ? "\n\nssh -i ${var.ssh_private_key_path} root@${module.nixos_server.server_ip}\n\n" : "\n\nssh root@${module.nixos_server.server_ip}\n\n"
}

