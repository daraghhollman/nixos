/*
  The base config for every machine. Networking, bootloader,
  locales, etc.
*/

{ config, pkgs, ... }:

{
  # Bootloader
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
  };

  # Locale & timezone
  time.timeZone = "Europe/Dublin";
  i18n.defaultLocale = "en_IE.UTF-8";

  console.keyMap = "ie";

  # User
  users.users.daragh = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
  };

  security.sudo.wheelNeedsPassword = true;

  # Packages
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
  ];

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow proprietary packages
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";

}
