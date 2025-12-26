output "server_ipv4_address" {
  description = "Public IPv4 address of the server"
  value       = module.nixos_server.server_ipv4_address
}

output "server_name" {
  description = "Name of the server"
  value       = module.nixos_server.server_name
}

output "ssh_key_name" {
  description = "Name of the SSH key"
  value       = module.nixos_server.ssh_key_name
}

output "firewall_name" {
  description = "Name of the firewall"
  value       = module.nixos_server.firewall_name
}

output "volume_id" {
  description = "ID of the volume (if created)"
  value       = module.nixos_server.volume_id
}