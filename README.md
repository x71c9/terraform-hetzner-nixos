# Terraform Hetzner NixOS

A Terraform module for deploying NixOS servers on Hetzner Cloud infrastructure.

## Purpose

This module automates the deployment of NixOS servers on Hetzner Cloud, which does not provide native NixOS images. The module provisions an Ubuntu server and uses nixos-anywhere to perform an in-place conversion to NixOS.

## Usage

Pin to a specific version (check the [releases page](https://github.com/x71c9/terraform-hetzner-nixos/releases) for all available versions):

```hcl
# Configure the Hetzner Cloud provider with HCLOUD_TOKEN environment variable
# export HCLOUD_TOKEN="your-token-here"
provider "hcloud" {
  # Authentication via HCLOUD_TOKEN env var
}

module "nixos_server" {
  source = "git::https://github.com/x71c9/terraform-hetzner-nixos.git?ref=v0.5.1"

  host_name          = "my-server"
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
}
```

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

## Post-Deployment

After initial deployment, the module automatically downloads NixOS configuration files to `./nixos-config/` (unless `download_nixos_config = false`).

### Managing Your Server

The downloaded configuration includes:
- `flake.nix` - Flake configuration with your hostname
- `disko.nix` - Disk partitioning configuration used during deployment
- `hardware-configuration.nix` - Hardware-specific settings
- `configuration.nix` - Basic system configuration (customize this file)

To apply configuration changes:

```bash
cd nixos-config
git add .
# Edit configuration.nix to add packages, services, users, etc.
nixos-rebuild switch --flake .#<hostname> --target-host root@<server-ip>
```

This is a starting point to update the remote machine, the `configuration.nix` file is intended to be replaced with future update of the machine.\ 
The other files ensure the hardware configuration of the machine.

### Customizing Your Configuration

Edit `nixos-config/configuration.nix` to:
- Add packages to `environment.systemPackages`
- Configure services (nginx, postgresql, etc.)
- Set up users and SSH keys
- Configure firewall rules
- Add your own NixOS modules

For more configuration options, visit [NixOS Search](https://search.nixos.org/options).

## Module Settings

### Authentication

The module requires the Hetzner Cloud provider to be configured. You can authenticate using either:

1. **Environment Variable (Recommended)**:
   ```bash
   export HCLOUD_TOKEN="your-hetzner-token-here"
   ```

2. **Provider Configuration**:
   ```hcl
   provider "hcloud" {
     token = var.hetzner_cloud_token
   }
   ```

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `host_name` | `string` | Host configuration name |
| `ssh_public_key_path` | `string` | SSH public key file path for accessing the server (only used if `ssh_key_name` is not provided) |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `additional_firewall_rules` | `list(object)` | `[]` | Additional firewall rules beyond SSH (22). Objects contain: `direction`, `port` (optional), `protocol`, `source_ips` |
| `download_nixos_config` | `bool` | `true` | Download NixOS configuration files to local nixos-config/ directory for easy nixos-rebuild usage |
| `enable_backups` | `bool` | `false` | Enable automatic backups |
| `enable_delete_protection` | `bool` | `false` | Enable delete protection (recommended for production) |
| `labels` | `map(string)` | `{}` | Additional labels for the server |
| `location` | `string` | `"nbg1"` | Hetzner Cloud location ([available locations](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server#location-1)) |
| `server_type` | `string` | `"cx23"` | Hetzner Cloud server type ([available types](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs/resources/server#server_type-1)) |
| `ssh_key_name` | `string` | `null` | Name of existing SSH key in Hetzner Cloud. If provided, the module will use this existing key instead of creating a new one (useful for deploying multiple servers with the same SSH key) |
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
| `firewall_name` | `string` | The name of the firewall created |
| `server_id` | `string` | The ID of the Hetzner Cloud server |
| `server_ip` | `string` | The public IPv4 address of the server |
| `server_ipv6` | `string` | The public IPv6 address of the server |
| `server_name` | `string` | The name of the server |
| `ssh_key_id` | `string` | The ID of the SSH key created |
| `ssh_key_name` | `string` | The name of the SSH key created |
| `volume_id` | `string` | The ID of the volume (if created, null otherwise) |
| `volume_name` | `string` | The name of the volume (if created, null otherwise) |

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

### Example Usage

#### Single Server Deployment

```hcl
# Configure Hetzner Cloud provider
# export HCLOUD_TOKEN="your-token-here"
provider "hcloud" {}

module "nixos_server" {
  source = "git::https://github.com/x71c9/terraform-hetzner-nixos.git?ref=vX.Y.Z"

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

#### Multiple Servers with Shared SSH Key

When deploying multiple servers, you can create a single SSH key and share it across all instances to avoid duplication:

```hcl
# Configure Hetzner Cloud provider
# export HCLOUD_TOKEN="your-token-here"
provider "hcloud" {}

# Create a shared SSH key once
resource "hcloud_ssh_key" "shared" {
  name       = "shared-nixos-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Deploy multiple servers using the shared key
module "web_server" {
  source = "git::https://github.com/x71c9/terraform-hetzner-nixos.git?ref=vX.Y.Z"

  host_name           = "web-server"
  ssh_key_name        = hcloud_ssh_key.shared.name
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
}

module "db_server" {
  source = "git::https://github.com/x71c9/terraform-hetzner-nixos.git?ref=vX.Y.Z"

  host_name           = "db-server"
  ssh_key_name        = hcloud_ssh_key.shared.name
  ssh_public_key_path = "~/.ssh/id_rsa.pub"
  volume_size         = 100
}

output "web_server_ip" {
  value = module.web_server.server_ip
}

output "db_server_ip" {
  value = module.db_server.server_ip
}
```
