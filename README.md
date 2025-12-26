# Terraform Hetzner NixOS

A Terraform module for deploying NixOS servers on Hetzner Cloud infrastructure.

## Purpose

This module automates the deployment of NixOS servers on Hetzner Cloud, which does not provide native NixOS images. The module provisions an Ubuntu server and uses nixos-anywhere to perform an in-place conversion to NixOS.

## Usage

```hcl
module "nixos_server" {
  source = "path/to/this/module"
  
  hetzner_cloud_token   = var.hetzner_cloud_token
  ssh_public_key_path   = var.ssh_public_key_path
}
```

## Examples

Three example configurations are provided in the `examples/` directory:

1. **basic** - Minimal NixOS server deployment
2. **volume** - Deployment with attached storage volumes
3. **complete** - Full-featured deployment with volumes and additional configurations

To use any example:

1. Copy `.env.example` to `.env` and configure your values
2. Source the environment: `source .env`
3. Initialize Terraform: `terraform init`
4. Apply the configuration: `terraform apply`

## Implementation Challenges

### Volume Detection

Hetzner Cloud does not provide a consistent naming scheme for attached volumes. The module implements regex-based volume detection to ensure NixOS installation targets the primary disk rather than attached storage volumes.

### Disk Configuration

A custom `disko.nix` configuration handles disk partitioning and ensures proper installation on the correct storage device, preventing accidental installation on attached volumes.

### System Templating

The module uses `.nix.tpl` template files to dynamically inject hostname and SSH public key configurations during deployment, enabling immediate SSH access to the deployed server.

## Post-Deployment

After initial deployment, manage the NixOS configuration using:

```bash
nixos-rebuild switch --target-host <server-ip>
```

This allows for declarative system management using your preferred NixOS flake configuration.