{ config, pkgs, ... }:

{
  # Enable Docker daemon if not done elsewhere
  virtualisation.docker.enable = true;

  # Env file containing (one per line):
  #   POSTGRES_PASSWORD=<openssl rand -hex 24>
  #   JWT_SECRET=<openssl rand -hex 32>
  #   SETUP_BOOTSTRAP_TOKEN=<openssl rand -hex 16>
  age.secrets.bookorbitEnv = {
    file = ../../../secrets/bookorbit-env.age;
    owner = "root";
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/bookorbit/app 0750 1000 1000 - -"
    "d /var/lib/bookorbit/books 0750 1000 1000 - -"
  ];

  # Shared network so the app can reach the database by container name
  systemd.services.bookorbit-network = {
    description = "Create Docker network for BookOrbit";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect bookorbit >/dev/null 2>&1 \
        || ${pkgs.docker}/bin/docker network create bookorbit
    '';
  };

  virtualisation.oci-containers = {
    backend = "docker";

    containers."bookorbit-db" = {
      image = "pgvector/pgvector:pg18";
      volumes = [
        "/var/lib/bookorbit/postgres:/var/lib/postgresql"
      ];
      environment = {
        POSTGRES_USER = "bookorbit";
        POSTGRES_DB = "bookorbit";
      };
      environmentFiles = [ config.age.secrets.bookorbitEnv.path ];
      extraOptions = [ "--network=bookorbit" ];
    };

    containers."bookorbit" = {
      image = "ghcr.io/bookorbit/bookorbit:latest";
      dependsOn = [ "bookorbit-db" ];
      ports = [ "127.0.0.1:3000:3000" ];
      volumes = [
        "/var/lib/bookorbit/app:/data"
        "/var/lib/bookorbit/books:/books" # change to your existing library path
      ];
      environment = {
        APP_URL = "https://books.daraghhollman.duckdns.org";
        POSTGRES_HOST = "bookorbit-db";
        POSTGRES_USER = "bookorbit";
        POSTGRES_DB = "bookorbit";
      };
      environmentFiles = [ config.age.secrets.bookorbitEnv.path ];
      extraOptions = [ "--network=bookorbit" ];
    };
  };

  # Containers need the network to exist first
  systemd.services.docker-bookorbit-db = {
    requires = [ "bookorbit-network.service" ];
    after = [ "bookorbit-network.service" ];
  };
  systemd.services.docker-bookorbit = {
    requires = [ "bookorbit-network.service" ];
    after = [ "bookorbit-network.service" ];
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "books.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3000
        '';
      };
    };
  };
}
