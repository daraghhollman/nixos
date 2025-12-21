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
    systemd.enable = false;
    xwayland.enable = true;
  };


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
  xdg.configFile."kitty/" =
    {
      source = config.lib.file.mkOutOfStoreSymlink "/home/daraghhollman/nixos/config/kitty/";
      recursive = true;
    };

  # Packages
  home.packages = with pkgs;
    [
      # Core
      kitty

      # Fonts
      courier-prime

      # Dev
      tmux
      neovim
    ];
}
