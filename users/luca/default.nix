{ config, pkgs, ... }:

{
  users.users.luca = {
    isNormalUser = true;
    extraGroups = [ "dail-leargas" "systemd-journal" ];
  };

  home-manager.users.luca = {
    imports = [
      ../../modules/home/shell/zsh.nix
      ../../modules/home/terminal/tmux.nix
    ];

    home.username = "luca";
    home.homeDirectory = "/home/luca";
    home.stateVersion = "25.11";
  };
}
