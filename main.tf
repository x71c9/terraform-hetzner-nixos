locals {
  server_name   = var.host_name
  firewall_name = "${var.host_name}-firewall"
  ssh_key_name  = "${var.host_name}-ssh-key"
  volume_name   = "${var.host_name}-volume"

  # Per-host isolated build directory. Each module instance materializes a
  # complete, self-contained NixOS flake here so that nothing is shared
  # between instances. NixOS flake imports are relative, so configuration.nix,
  # disko.nix, flake.nix and hardware-configuration.nix must all live together
  # in this single directory.
  generated_dir = "${path.module}/.generated/${var.host_name}"

  # Determine which SSH keys to use
  ssh_key_ids = length(var.ssh_key_ids) > 0 ? (
    var.ssh_key_ids
    ) : (
    [hcloud_ssh_key.new[0].id]
  )

  # Get the actual SSH public key content for NixOS config
  ssh_public_key_content = length(var.ssh_key_ids) > 0 ? (
    data.hcloud_ssh_key.existing[0].public_key
    ) : (
    trimspace(file(var.ssh_public_key_path))
  )
}

# Data source for existing SSH key (if ssh_key_ids is provided) - only fetch first one for public key
data "hcloud_ssh_key" "existing" {
  count = length(var.ssh_key_ids) > 0 ? 1 : 0
  id    = var.ssh_key_ids[0]
}

# Create new SSH key only if ssh_key_ids is empty
resource "hcloud_ssh_key" "new" {
  count      = length(var.ssh_key_ids) == 0 ? 1 : 0
  name       = local.ssh_key_name
  public_key = file(var.ssh_public_key_path)
}

resource "hcloud_server" "server" {
  name               = local.server_name
  image              = "ubuntu-22.04"
  server_type        = var.server_type
  location           = var.location
  ssh_keys           = local.ssh_key_ids
  backups            = var.enable_backups
  delete_protection  = var.enable_server_delete_protection
  rebuild_protection = var.enable_server_delete_protection
  firewall_ids       = [hcloud_firewall.firewall.id]

  labels = var.labels

  lifecycle {
    # ssh_keys are only consumed at server creation and are not reported back by
    # the Hetzner API. Ignoring them prevents a forced replacement (disk wipe) when
    # the key resource is recreated, e.g. after moving the server between projects.
    ignore_changes = [ssh_keys]
  }
}

resource "hcloud_firewall" "firewall" {
  name = local.firewall_name

  rule {
    direction  = "in"
    port       = "22"
    protocol   = "tcp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  dynamic "rule" {
    for_each = var.additional_firewall_rules
    content {
      direction  = rule.value.direction
      port       = rule.value.port
      protocol   = rule.value.protocol
      source_ips = rule.value.source_ips
    }
  }
}

resource "hcloud_volume" "volume" {
  count    = var.volume_size != null ? 1 : 0
  name     = local.volume_name
  size     = var.volume_size
  location = var.location
  format   = "xfs"

  delete_protection = var.enable_volume_delete_protection
}

resource "hcloud_volume_attachment" "volume_attachment" {
  count     = var.volume_size != null ? 1 : 0
  volume_id = hcloud_volume.volume[0].id
  server_id = hcloud_server.server.id
  automount = true
}

# Materialize a complete, per-host NixOS flake into the isolated generated
# directory. Every file the deployment flake needs is written here so that no
# two module instances ever share a file. The source files in nix/ are pure
# templates/statics and are never mutated.

resource "local_file" "nixos_configuration" {
  content = templatefile("${path.module}/nix/configuration.nix.tpl", {
    hostname           = var.host_name
    ssh_public_key     = local.ssh_public_key_content
    volume_size        = var.volume_size
    volume_mount_point = var.volume_mount_point
  })
  filename = "${local.generated_dir}/configuration.nix"
}

resource "local_file" "nixos_flake" {
  content  = file("${path.module}/nix/flake.nix")
  filename = "${local.generated_dir}/flake.nix"
}

resource "local_file" "nixos_flake_lock" {
  content  = file("${path.module}/nix/flake.lock")
  filename = "${local.generated_dir}/flake.lock"
}

resource "local_file" "nixos_hardware_configuration" {
  content  = file("${path.module}/nix/hardware-configuration.nix")
  filename = "${local.generated_dir}/hardware-configuration.nix"
}

# disko.nix is rendered from a template with a __DISK_DEVICE__ placeholder. The
# real device is detected over SSH at deploy time and substituted into this
# per-host copy by the deployment provisioner.
resource "local_file" "nixos_disko" {
  content  = file("${path.module}/nix/disko.nix.tpl")
  filename = "${local.generated_dir}/disko.nix"
}

resource "null_resource" "nixos_deployment" {
  depends_on = [
    hcloud_server.server,
    local_file.nixos_configuration,
    local_file.nixos_flake,
    local_file.nixos_flake_lock,
    local_file.nixos_hardware_configuration,
    local_file.nixos_disko,
  ]

  triggers = {
    server_id = hcloud_server.server.id
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -e  # Exit on any error
      
      # Wait for server to be ready
      sleep 30
      
      # Remove old host key
      ssh-keygen -R ${hcloud_server.server.ipv4_address} || true

      # Setup SSH key arguments if private key is provided
      SSH_KEY_ARGS=""
      if [[ -n "${var.ssh_private_key_path}" ]]; then
        SSH_KEY_ARGS="-i ${var.ssh_private_key_path}"
      fi

      # Detect main disk and update disko config
      MAIN_DISK=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SSH_KEY_ARGS root@${hcloud_server.server.ipv4_address} \
        "find /dev/disk/by-id/ -name 'scsi-0QEMU_QEMU_HARDDISK*' | grep -v 'part[0-9]' | head -1")
      
      echo "Detected main disk: $MAIN_DISK"
      
      # Fallback to /dev/sda if detection fails
      if [ -z "$MAIN_DISK" ]; then
        echo "No QEMU disk found, using /dev/sda as fallback"
        MAIN_DISK="/dev/sda"
      fi
      
      # Substitute the detected disk into THIS host's generated disko.nix only.
      # The source template (nix/disko.nix.tpl) is never touched, and other
      # module instances have their own ${local.generated_dir} copy, so
      # concurrent deployments cannot race on a shared file.
      sed -i "s|device = \"__DISK_DEVICE__\";|device = \"$MAIN_DISK\";|" \
        ${local.generated_dir}/disko.nix

      # All flake files (configuration.nix, disko.nix, flake.nix, flake.lock,
      # hardware-configuration.nix) are already materialized per-host by the
      # terraform local_file resources into ${local.generated_dir}.

      # Deploy NixOS with flake using private key if provided
      NIXOS_ANYWHERE_ARGS=""
      if [[ -n "${var.ssh_private_key_path}" ]]; then
        NIXOS_ANYWHERE_ARGS="-i ${var.ssh_private_key_path}"
      fi

      # Use path: prefix to include the per-host generated files which are not
      # versioned in git.
      if ! nix run github:nix-community/nixos-anywhere -- $NIXOS_ANYWHERE_ARGS --flake path:${local.generated_dir}#default root@${hcloud_server.server.ipv4_address} ; then
        echo "ERROR: nixos-anywhere deployment failed!"
        exit 1
      fi
      
      echo "SUCCESS: NixOS deployment completed"
    EOF

    working_dir = path.cwd
  }
}

resource "null_resource" "download_nixos_config" {
  count = var.download_nixos_config ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
      set -euo pipefail

      # Per-host output directory so multiple module instances never clobber
      # each other's downloaded configuration.
      DEST="nixos-config/${var.host_name}"
      mkdir -p "$DEST"

      # Resolve the GitHub ref to download from.
      #
      # Priority:
      #   1. Tag pointing at HEAD in the module clone (set by `terraform init`
      #      when the source uses `?ref=vX.Y.Z`).
      #   2. The ?ref= value recorded in .terraform/modules/modules.json, which
      #      Terraform always writes and which contains the exact source URL.
      #   3. Commit SHA as a last resort (works only for commits reachable from
      #      a public branch on GitHub; fails for shallow/detached checkouts on
      #      private or unreleased commits).
      #
      # Using a tag or named ref is preferred because GitHub's raw content CDN
      # serves those reliably. A bare commit SHA returns 404 unless the commit
      # is reachable from a public branch or tag.
      #
      # Guard: only query git if path.module has its own .git directory.
      # Without this check, git walks up to the caller's repo root and returns
      # that repo's tags instead (e.g. when Terraform unpacks the module as a
      # plain directory inside .terraform/modules/ with no .git of its own).
      GITHUB_REF=""
      if [ -d "${path.module}/.git" ]; then
        GITHUB_REF=$(git -C ${path.module} tag --points-at HEAD 2>/dev/null | head -1)
      fi

      if [ -z "$GITHUB_REF" ]; then
        MODULES_JSON="${path.cwd}/.terraform/modules/modules.json"
        if [ -f "$MODULES_JSON" ]; then
          # Extract the ?ref= value from the source URL recorded for this module.
          GITHUB_REF=$(grep -o '?ref=[^"]*' "$MODULES_JSON" | head -1 | sed 's/?ref=//')
        fi
      fi

      if [ -z "$GITHUB_REF" ] && [ -d "${path.module}/.git" ]; then
        GITHUB_REF=$(git -C ${path.module} rev-parse HEAD)
      fi

      echo "Downloading NixOS config files at ref $GITHUB_REF"

      # --fail makes curl exit non-zero on HTTP 4xx/5xx so bad responses are
      # never silently written as file content.
      BASE="https://raw.githubusercontent.com/x71c9/terraform-hetzner-nixos/$GITHUB_REF"
      curl -fsSL "$BASE/nix/disko.nix.tpl" -o "$DEST/disko.nix"
      curl -fsSL "$BASE/nix/hardware-configuration.nix" -o "$DEST/hardware-configuration.nix"
      curl -fsSL "$BASE/nix/flake.nix" -o "$DEST/flake.nix"
      curl -fsSL "$BASE/tmpl/configuration.nix" -o "$DEST/configuration.nix"

      # Replace placeholders so the downloaded config is directly usable.
      # disko.nix.tpl carries the __DISK_DEVICE__ placeholder; default to
      # /dev/sda for manual rebuilds (the live system already has its real
      # layout from the initial nixos-anywhere deployment).
      sed -i 's/HOSTNAME/${var.host_name}/g' "$DEST/configuration.nix"
      sed -i 's|device = "__DISK_DEVICE__";|device = "/dev/sda";|' "$DEST/disko.nix"

      echo "NixOS configuration downloaded to ./$DEST/"
      echo "To manage your server, run: nixos-rebuild switch --flake ./$DEST#default --target-host root@${hcloud_server.server.ipv4_address}"
    EOF

    working_dir = path.cwd
  }

  depends_on = [null_resource.nixos_deployment]
}
