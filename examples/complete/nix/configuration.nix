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
}
