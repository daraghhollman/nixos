{ config, pkgs, ... }:

{
  home-manager.users.daragh = {
    imports = [
      ../../modules/home/shell/zsh.nix
      ../../modules/home/gui/sway.nix
      ../../modules/home/editor/nvim.nix
    ];

    home.username = "daragh";
    home.homeDirectory = "/home/daragh";
    home.stateVersion = "26.05";

    home.sessionVariables = {
      EDITOR="nvim";
    };

    # Daragh's personal sway config
    wayland.windowManager.sway.config = {
      modifier = "Mod4";
      terminal = "foot";
      menu = "wmenu-run";

      keybindings =
        let
          modifier = config.home-manager.users.daragh.wayland.windowManager.sway.config.modifier;
        in
        {
          "${modifier}+Return" = "exec foot";
          "${modifier}+d" = "exec wmenu-run";
          "${modifier}+Shift+q" = "kill";
          "${modifier}+Shift+e" = "exec swaymsg exit";
          "${modifier}+Shift+r" = "reload";

          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";

          "${modifier}+1" = "workspace number 1";
          "${modifier}+2" = "workspace number 2";
          "${modifier}+3" = "workspace number 3";
          "${modifier}+4" = "workspace number 4";
          "${modifier}+5" = "workspace number 5";
        };
    };

    home.packages = with pkgs; [
      foot
      wmenu
      waybar
	firefox
    ];
  };
}
