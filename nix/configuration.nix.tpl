{ pkgs, ... }:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.05";

  networking.hostName = "${hostname}";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  environment.systemPackages = with pkgs; [
    vim
    curl
    git
  ];

  users.users.root = {
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "${ssh_public_key}"
    ];
  };

%{ if volume_size != null ~}
  # Auto-mount Hetzner Cloud volume service
  systemd.services.mount-hetzner-volume = {
    description = "Auto-mount Hetzner Cloud volume";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    script = ''
      # Find Hetzner volume by ID pattern (any HC_Volume)
      VOLUME_DEV=$(find /dev/disk/by-id/ -name "scsi-0HC_Volume_*" | head -1)
      if [ -n "$VOLUME_DEV" ]; then
        MOUNT_POINT="${volume_mount_point}"
        mkdir -p "$MOUNT_POINT"
        
        # Mount if not already mounted
        if ! $${pkgs.util-linux}/bin/mountpoint -q "$MOUNT_POINT"; then
          $${pkgs.util-linux}/bin/mount "$VOLUME_DEV" "$MOUNT_POINT"
          echo "Mounted $VOLUME_DEV at $MOUNT_POINT"
        else
          echo "$MOUNT_POINT already mounted"
        fi
      else
        echo "No Hetzner volume found"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
%{ endif ~}
}
