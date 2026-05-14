{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Host roles
    ../../modules/nixos/roles/core.nix

    # Users
    ../../users/daragh/default.nix
  ];

  # Hostname
  networking.hostName = "curie";
}
