{ config, pkgs, ... }:

{
  # Enable Docker daemon if not done elsewhere
  virtualisation.docker.enable = true;

  age.secrets.fireflyAppKey = {
    file = ../../../secrets/firefly-app-key.age;
    owner = "root";
    mode = "0400";
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "firefly" ];
    ensureUsers = [{
      name = "firefly";
      ensureDBOwnership = true;
    }];
    # Allow local TCP connections from the host/Docker bridge network interface
    settings = {
      listen_addresses = pkgs.lib.mkForce "127.0.0.1, 172.17.0.1";
    };
    authentication = pkgs.lib.mkAfter ''
      # Allow local connections from the host itself
      local firefly firefly peer map=firefly
      host  firefly firefly 127.0.0.1/32 trust
      host  firefly firefly 172.17.0.0/16 trust
    '';
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers."firefly-iii" = {
      image = "fireflyiii/core:latest";
      ports = [ "127.0.0.1:8080:8080" ];

      environment = {
        APP_URL = "https://firefly.daraghhollman.duckdns.org";
        APP_ENV = "production";
        DB_CONNECTION = "pgsql";
        DB_HOST = "172.17.0.1";
        DB_PORT = "5432";
        DB_DATABASE = "firefly";
        DB_USERNAME = "firefly";
        DB_PASSWORD = "";

        DISABLE_REGISTRATION = "true";
        DEFAULT_LANGUAGE = "en_GB";
        DEFAULT_LOCALE = "en_US.UTF-8";
        LC_ALL = "en_US.UTF-8";
        TZ = "Europe/Dublin";

        TRUSTED_PROXIES = "**";
      };

      environmentFiles = [
        config.age.secrets.fireflyAppKey.path
      ];
    };
  };

  # Firefly III Cron Job to manage budget repetition (among other things)
  systemd.services.firefly-iii-cron = {
    description = "Firefly III daily cron job";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.docker}/bin/docker exec firefly-iii /usr/local/bin/php /var/www/html/artisan firefly-iii:cron";
    };
    startAt = "*-*-* 03:00:00";
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "firefly.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8080
        '';
      };
    };
  };

  networking.firewall.trustedInterfaces = [ "docker0" ];
}
