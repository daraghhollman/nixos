{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/display-managers/gdm.nix
    ];

  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking = {
    hostName = "galileo";
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Dublin";

  console.keyMap = "uk";

  services = {
    printing.enable = true;

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
  security.rtkit.enable = true;

  users.users.daraghhollman = {
    isNormalUser = true;
    description = "Daragh Hollman";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";

}
