# Terraform Hetzner NixOS

A Terraform module for deploying NixOS servers on Hetzner Cloud infrastructure.

## Purpose

This module automates the deployment of NixOS servers on Hetzner Cloud, which does not provide native NixOS images. The module provisions an Ubuntu server and uses nixos-anywhere to perform an in-place conversion to NixOS.

## Usage

Pin to a specific version:

```hcl
module "nixos_server" {
  source = "git::https://github.com/x71c9/terraform-hetzner-nixos.git?ref=v0.1.0"
  
  hetzner_cloud_token = var.hetzner_cloud_token
  host_name          = "my-server"
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
}
```

### Available Versions

Check the [releases page](https://github.com/x71c9/terraform-hetzner-nixos/releases) for all available versions.

## Examples

Three example configurations are provided in the `examples/` directory:

1. **basic** - Minimal NixOS server deployment
2. **volume** - Deployment with attached storage volumes
3. **complete** - Full-featured deployment with volumes and additional configurations

To use any example:

Navigate to the desired example directory:
```bash
cd ./examples/basic
```

Create and configure the environment file:
```bash
cp .env.example .env
vim .env
```

Source the environment and deploy:
```bash
source .env
terraform init
terraform apply
```

## Implementation Challenges

### Volume Detection

Hetzner Cloud does not provide a consistent naming scheme for attached volumes. The module implements regex-based volume detection to ensure NixOS installation targets the primary disk rather than attached storage volumes.

### Disk Configuration

A custom `disko.nix` configuration handles disk partitioning and ensures proper installation on the correct storage device, preventing accidental installation on attached volumes.

### System Templating

The module uses `.nix.tpl` template files to dynamically inject hostname and SSH public key configurations during deployment, enabling immediate SSH access to the deployed server.

## NixOS System Configuration

The deployed NixOS system includes:

- **Base System**: NixOS 25.05 with experimental features (nix-command, flakes) enabled
- **Security**: SSH-only root access with password authentication disabled, firewall enabled (port 22 only)
- **Essential Tools**: vim, curl, git pre-installed
- **Volume Support**: Automatic detection and mounting of Hetzner Cloud volumes using systemd service
- **Template Variables**: Dynamic hostname and SSH key injection via Terraform templating

The system is configured for immediate SSH access and supports optional volume attachment with automatic mounting at specified mount points.

## Post-Deployment

After initial deployment, manage the NixOS configuration using:

```bash
nixos-rebuild switch --flake .#<hostname> --target-host <server-ip>
```

This allows for declarative system management using your preferred NixOS flake configuration.

## Module Settings

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `hetzner_cloud_token` | `string` | Hetzner Cloud API Token (sensitive) |
| `host_name` | `string` | Host configuration name |
| `ssh_public_key_path` | `string` | SSH public key file path for accessing the server |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `additional_firewall_rules` | `list(object)` | `[]` | Additional firewall rules beyond SSH (22). Objects contain: `direction`, `port` (optional), `protocol`, `source_ips` |
| `enable_backups` | `bool` | `false` | Enable automatic backups |
| `enable_delete_protection` | `bool` | `false` | Enable delete protection (recommended for production) |
| `labels` | `map(string)` | `{}` | Additional labels for the server |
| `location` | `string` | `"nbg1"` | Hetzner Cloud location ([available locations](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server#location-1)) |
| `server_type` | `string` | `"cx23"` | Hetzner Cloud server type ([available types](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server#server_type-1)) |
| `ssh_private_key_path` | `string` | `""` | SSH private key file path for accessing the server |
| `volume_size` | `number` | `null` | Size of the additional volume in GB (optional) |
| `volume_mount_point` | `string` | `"/mnt/data"` | Mount point for the additional volume (only used if volume_size is set) |

### Firewall Rules Format

The `additional_firewall_rules` variable accepts a list of objects with the following structure:

```hcl
additional_firewall_rules = [
  {
    direction  = "in"        # Required: "in" or "out"
    port       = "80"        # Optional: port number or range
    protocol   = "tcp"       # Required: "tcp", "udp", "icmp", etc.
    source_ips = ["0.0.0.0/0", "::/0"]  # Required: list of IP addresses/ranges
  }
]
```

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `server_id` | `string` | The ID of the Hetzner Cloud server |
| `server_ip` | `string` | The public IPv4 address of the server |
| `server_ipv6` | `string` | The public IPv6 address of the server |
| `server_name` | `string` | The name of the server |
| `server_ipv4_address` | `string` | The public IPv4 address of the server (alias for server_ip) |
| `ssh_key_id` | `string` | The ID of the SSH key created |
| `ssh_key_name` | `string` | The name of the SSH key created |
| `firewall_name` | `string` | The name of the firewall created |
| `volume_id` | `string` | The ID of the volume (if created, null otherwise) |
| `volume_name` | `string` | The name of the volume (if created, null otherwise) |

### Example Usage

```hcl
module "nixos_server" {
  source = "git::https://github.com/x71c9/terraform-hetzner-nixos.git?ref=v0.1.0"
  
  hetzner_cloud_token = var.hetzner_cloud_token
  host_name          = "my-server"
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
}

output "server_public_ip" {
  value = module.nixos_server.server_ip
}

output "ssh_command" {
  value = "ssh root@${module.nixos_server.server_ip}"
}
```
