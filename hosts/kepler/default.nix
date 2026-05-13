{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    # Host roles
    ../../modules/nixos/roles/core.nix
    ../../modules/nixos/roles/gui.nix

    # Hardware specific
    ../../modules/nixos/hardware/intel-graphics.nix

    # Users
    ../../users/daragh/default.nix
  ];

  # Hostname
  networking.hostName = "kepler";
  roles.gui.defaultSession = "sway";
}
