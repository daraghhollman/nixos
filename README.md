# My NixOS Config

## Installation

[Install NixOS](https://nixos.wiki/wiki/NixOS_Installation_Guide) from minimal ISO (Tested with nixos-minimal-25.11).

Make sure to include git in `enviroment.systemPackages`

Enable required experimental options for flakes by adding the following to your configuration.nix:
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Clone this repository
```shell
git clone https://github.com/daraghhollman/nixos
```
