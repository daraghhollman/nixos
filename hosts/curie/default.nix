{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Host roles
    ../../modules/nixos/roles/core.nix
    ../../modules/nixos/roles/server.nix

    # Users
    ../../users/daragh/default.nix
  ];

  # Hostname
  networking.hostName = "curie";
  networking.hostId = "b4811afc";

  boot.zfs.extraPools = [ "storage" ];

  # Fan control modules
  boot.kernelModules = [ "coretemp" "nct6775" ];
}
