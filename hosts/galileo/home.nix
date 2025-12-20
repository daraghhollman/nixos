{ config, pkgs, ... }:

{
	home.username = "daraghhollman";
	home.homeDirectory = "/home/daraghhollman";
	home.stateVersion = "25.11";

	programs.bash = {
		enable = true;
		shellAliases = {
			btw = "echo this works"
		};
	};
}
