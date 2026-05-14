{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/nixos#$(hostname)";
      update = "sudo nix flake update ~/nixos";
    };

    history = {
      size = 10000;
      save = 10000;
    };
  };
}
