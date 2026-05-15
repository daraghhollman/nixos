{
  description = "Daragh's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix.url = "github:ryantm/agenix";
  };

  outputs = { self, nixpkgs, home-manager, agenix, ... }:
    let
      system = "x86_64-linux";

      # Helper function — given a hostname, builds a full nixosSystem config
      # It automatically imports ./hosts/<name>/default.nix
      mkHost = name: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          agenix.nixosModules.default

          ({ pkgs, ... }: {
            environment.systemPackages = [
              agenix.packages.${pkgs.system}.default
            ];
          })

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
          ./hosts/${name}/default.nix
        ];
      };

      hosts = [ "kepler" "curie" ];

    in
    {
      nixosConfigurations = builtins.listToAttrs (map
        (name: {
          inherit name;
          value = mkHost name;
        })
        hosts);
    };
}
