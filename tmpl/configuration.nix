# Basic NixOS configuration for your deployed server
# 
# This is a minimal starting configuration. You can customize it by:
# 1. Adding packages to environment.systemPackages
# 2. Configuring services (nginx, postgresql, etc.)
# 3. Setting up users and groups
# 4. Configuring networking and firewall rules
# 5. Adding your own modules and configurations
#
# After making changes, apply them with:
# nixos-rebuild switch --flake .#HOSTNAME --target-host root@SERVER_IP
#
# For more configuration options, see:
# https://search.nixos.org/options

{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];
  # Basic packages - add your own here
  environment.systemPackages = with pkgs; [
    vim
    curl
    git
    htop
    # Add more packages as needed
  ];

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    # Add more ports as needed: allowedTCPPorts = [ 22 80 443 ];
  };

  # Hostname will be set by the deployment
  networking.hostName = "HOSTNAME";

  # Enable experimental features for flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "yes";
    };
  };

  # Basic system configuration
  system.stateVersion = "25.05";

  # Example user configuration (uncomment and customize)
  # users.users.myuser = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" "networkmanager" ];
  #   openssh.authorizedKeys.keys = [
  #     "ssh-rsa YOUR_PUBLIC_KEY_HERE"
  #   ];
  # };
}
