{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:
pkgs.mkShell {
  packages = [
    pkgs.terraform
    pkgs.hcloud
  ];
  shellHook = ''
    echo "terraform: $(terraform -v)"
    echo "hcloud: $(hcloud version)"
  '';
}
