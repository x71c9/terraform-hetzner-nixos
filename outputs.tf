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
  description = "The ID of the SSH key created"
  value       = hcloud_ssh_key.ssh_public_key.id
}
