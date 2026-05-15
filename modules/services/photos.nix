{ config, pkgs, ... }:

{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    mediaLocation = "/mnt/personal/immich/";
  };
}
