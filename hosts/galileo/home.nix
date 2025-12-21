{ config, pkgs, ... }:

{
  home.username = "daraghhollman";
  home.homeDirectory = "/home/daraghhollman";
  home.stateVersion = "25.11";
  programs.bash = {
    enable = true;
    shellAliases = {
      test = "echo this is a test";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];


  # Env variables
  home.sessionVariables =
    {
      EDITOR = "nvim";
    };

  # Add dotfiles
  xdg.configFile."hypr/" =
    {
      source = config.lib.file.mkOutOfStoreSymlink "/home/daraghhollman/nixos/config/hypr/";
      recursive = true;
    };

  # Packages
  home.packages = with pkgs;
    [
      tmux
      neovim
    ];
}
