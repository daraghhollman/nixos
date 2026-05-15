{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Host roles
    ../../modules/nixos/roles/core.nix
    ../../modules/nixos/roles/server.nix

    # Host extras
    ../../modules/services/photos.nix
    # ../../modules/nixos/roles/media-server.nix

    # Users
    ../../users/daragh/default.nix
  ];

  # Hostname
  networking.hostName = "curie";
  networking.hostId = "b4811afc";

  boot.zfs.extraPools = [ "storage" ];
}
