{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Host roles
    ../../modules/nixos/roles/core.nix
    ../../modules/nixos/roles/media-server.nix

    # Users
    ../../users/daragh/default.nix
  ];

  # Hostname
  networking.hostName = "curie";
}
