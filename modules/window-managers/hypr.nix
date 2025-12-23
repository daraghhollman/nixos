{ config, pkgs, ... }: {

  # Make sure to add
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Screensharing
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };

  # Enable the rest of the ecosystem
  environment.systemPackages = with pkgs; [
    hyprlock
    hypridle
    hyprpaper
    hyprsunset
    hyprpicker
  ];

}
