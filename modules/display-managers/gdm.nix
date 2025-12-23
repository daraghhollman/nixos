{ config, pkgs, ... }: {

  services.displayManager.gdm = {
    enable = true;
    banner = "This is a gdm banner";
  };

}
