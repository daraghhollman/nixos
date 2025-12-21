{ config, pkgs, ... }:

{
  home.username = "daraghhollman";
  home.homeDirectory = "/home/daraghhollman";
  programs.bash = {
    enable = true;
    shellAliases = {
      test = "echo this is a test";
    };
  };
}
