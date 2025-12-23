{ config, pkgs, split-monitor-workspaces, ... }:

{
  home.username = "daraghhollman";
  home.homeDirectory = "/home/daraghhollman";
  home.stateVersion = "25.11";
  programs.bash = {
    enable = true;
  };

  # Add dotfiles
  xdg.configFile."hypr/" =
    {
      source = config.lib.file.mkOutOfStoreSymlink "/home/daraghhollman/nixos/config/hypr/";
      recursive = true;
    };
  xdg.configFile."kitty/" =
    {
      source = config.lib.file.mkOutOfStoreSymlink "/home/daraghhollman/nixos/config/kitty/";
      recursive = true;
    };
  xdg.configFile."waybar/" =
    {
      source = config.lib.file.mkOutOfStoreSymlink "/home/daraghhollman/nixos/config/waybar/";
      recursive = true;
    };

  # Add plugins
  wayland.windowManager.hyprland = {
    plugins = [
      split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
    ];
  };

  # Packages
  home.packages = with pkgs;
    [
      # Core
      kitty
      pywal16

      # Fonts
      courier-prime

      # Dev
      tmux
      neovim
    ];

  programs.git.settings.user = {
    name = "daraghhollman";
    email = "hollmandaragh@gmail.com";
  };
}
