{ config, pkgs, ... }: {

  # Make sure to add
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

}
