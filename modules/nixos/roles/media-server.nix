{ config, pkgs, ... }:

{
  # Arion handles docker compose things
  modules = [ arion.nixosModules.arion ];

  virtualisation.arion = {
    backend = "docker";
    projects = {
      "transmission-openvpn".settings.services."transmission-openvpn".service = {
        image = "haugene/transmission-openvpn";
        ports = "9091:9091";
        environment = {
          OPENVPN_PROVIDER = "custom";
          # WIP
        };

      };
    };
  };
}
