{ config, pkgs, ... }:

{
  age.secrets.protonEnv = {
    file = ../../../secrets/proton-env.age;
  };

  # Adds transmission-openvpn on the local network. We don't expose this to the internet.
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      transmission-openvpn = {
        image = "haugene/transmission-openvpn";
        environmentFiles = [ config.age.secrets.protonEnv.path ];
        environment = {
          OPENVPN_PROVIDER = "PROTONVPN";
          OPENVPN_CONFIG = "uk.protonvpn.udp";
          LOCAL_NETWORK = "192.168.0.0/16";
          DISABLE_PORT_FORWARDER = "false";
        };
        volumes = [
          "/mnt/media/torrents/:/data"
          "/mnt/media/.transmission-config/:/config"
        ];
        ports = [ "9091:9091" ];
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--device=/dev/net/tun"
        ];
      };
    };
  };
}
