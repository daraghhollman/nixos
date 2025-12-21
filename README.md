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
git clone --recurse-submodules https://github.com/daraghhollman/nixos
```

Create a new build by copying a host
```shell
cp -r ~/nixos/hosts/<host>/ ~/nixos/hosts/<new-host>
cp /etc/nixos/hardware-configuration.nix ~/nixos/hosts/<new-host>/hardware-configuration.nix
#

# All of these files must be tracked by github to be recognised by flakes
cd nixos
git add .
git commit -m "Created new host <new-host>"
```
