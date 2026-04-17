output "server_id" {
  description = "The ID of the Hetzner Cloud server"
  value       = hcloud_server.server.id
}

output "server_ip" {
  description = "The public IPv4 address of the server"
  value       = hcloud_server.server.ipv4_address
}

output "server_ipv6" {
  description = "The public IPv6 address of the server"
  value       = hcloud_server.server.ipv6_address
}

output "server_name" {
  description = "The name of the server"
  value       = hcloud_server.server.name
}

output "ssh_key_id" {
  description = "The ID of the SSH key (either existing or newly created)"
  value       = local.ssh_key_id
}

output "ssh_key_name" {
  description = "The name of the SSH key (either existing or newly created)"
  value       = var.ssh_key_name != null ? var.ssh_key_name : local.ssh_key_name
}

output "firewall_name" {
  description = "The name of the firewall created"
  value       = hcloud_firewall.firewall.name
}

output "server_ipv4_address" {
  description = "The public IPv4 address of the server (alias for server_ip)"
  value       = hcloud_server.server.ipv4_address
}

output "volume_id" {
  description = "The ID of the volume (if created)"
  value       = var.volume_size != null ? hcloud_volume.volume[0].id : null
}

output "volume_name" {
  description = "The name of the volume (if created)"
  value       = var.volume_size != null ? hcloud_volume.volume[0].name : null
}
