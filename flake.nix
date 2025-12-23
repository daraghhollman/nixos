{
  description = "Daragh's NixOS config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }: {

    nixosConfigurations = {
      galileo =
        let
          username = "daraghhollman";
          specialArgs = { inherit username; };
        in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";

          modules = [
            ./hosts/galileo

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                extraSpecialArgs = inputs // specialArgs;
                users.${username} = import ./users/${username}/home.nix;
                backupFileExtension = "backup";

              };
            }
          ];
        };
    };
  };
}
