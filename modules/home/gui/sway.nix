{ config, pkgs, ... }:

{
  wayland.windowManager.sway.enable = true;

  home.packages = with pkgs; [
    swaylock
    swayidle
    grim
    slurp
    wl-clipboard
  ];
}
