{ config, lib, pkgs, ... }:

# Use the latest ZFS-compatible kernel
let
  zfsCompatibleKernelPackages = lib.filterAttrs
    (
      name: kernelPackages:
        (builtins.match "linux_[0-9]+_[0-9]+" name) != null
        && (builtins.tryEval kernelPackages).success
        && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken)
    )
    pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last (
    lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version)) (
      builtins.attrValues zfsCompatibleKernelPackages
    )
  );
in
{
  imports = [
    ../self-hosted/firefly.nix
    ../self-hosted/transmission-openvpn.nix
  ];

  # Note this might jump back and forth as kernels are added or removed.
  boot.kernelPackages = latestKernelPackage;

  # ZFS Setup
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # DuckDNS
  age.secrets.duckdns-token = {
    file = ../../../secrets/duckdns-token.age;
    mode = "0400";
    owner = "root";
  };
  age.secrets.paperless-key = {
    file = ../../../secrets/paperless-key.age;
    mode = "0400";
    owner = "paperless";
  };
  age.secrets.paperless-admin-password = {
    file = ../../../secrets/paperless-admin-password.age;
    mode = "0400";
    owner = "paperless";
  };

  # Cron to update ip for DuckDNS
  systemd.services.duckdns = {
    description = "DuckDNS IP updater";
    after = [ "network-online.target" "agenix.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "duckdns-update" ''
        TOKEN=$(cat ${config.age.secrets.duckdns-token.path})
        DOMAIN="daraghhollman.duckdns.org"
        ${pkgs.curl}/bin/curl -fsS \
          "https://www.duckdns.org/update?domains=$DOMAIN&token=$TOKEN&ip=" \
          -o /tmp/duckdns.log
        cat /tmp/duckdns.log
      '';
    };
  };

  systemd.timers.duckdns = {
    description = "DuckDNS IP updater timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
      Unit = "duckdns.service";
    };
  };

  # Caddy reverse proxy
  services.caddy = {
    enable = true;

    virtualHosts = {
      "https://daraghhollman.duckdns.org" = {
        extraConfig = ''
          redir https://daraghhollman.github.io permanent
        '';
      };
      "ollama.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy localhost:8080
        '';
      };
      "immich.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy localhost:2283
        '';
      };
      "jellyfin.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy localhost:8096
        '';
      };
      "paperless.daraghhollman.duckdns.org" = {
        extraConfig = ''
          header {
            Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
            X-Content-Type-Options "nosniff"
            X-Frame-Options "SAMEORIGIN"
            Referrer-Policy "strict-origin-when-cross-origin"
            Permissions-Policy "geolocation=(), microphone=(), camera=()"
            -Server
          }
          reverse_proxy localhost:${toString config.services.paperless.port}
        '';
      };
      "chessstack.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy localhost:3000
        '';
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };


  # Immich
  services.immich = {
    enable = true;
    port = 2283;
    host = "0.0.0.0";
    openFirewall = true;
    mediaLocation = "/mnt/media/immich";
  };

  services.paperless = {
    enable = true;
    port = 28981;
    address = "127.0.0.1";
    dataDir = "/mnt/media/paperless/data";
    mediaDir = "/mnt/media/paperless/media";
    consumptionDir = "/mnt/media/paperless/consume";

    passwordFile = config.age.secrets.paperless-admin-password.path;

    settings = {
      PAPERLESS_SECRET_KEY_FILE = config.age.secrets.paperless-key.path;
      PAPERLESS_URL = "https://paperless.daraghhollman.duckdns.org";
      PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://paperless.daraghhollman.duckdns.org";
      PAPERLESS_ALLOWED_HOSTS = "paperless.daraghhollman.duckdns.org,localhost,127.0.0.1";
      PAPERLESS_SESSION_COOKIE_SECURE = true;
      PAPERLESS_CSRF_COOKIE_SECURE = true;
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_FILENAME_FORMAT = "{created_year}/{correspondent}/{title}";
      PAPERLESS_ACCOUNT_LOGIN_ATTEMPTS_LIMIT = 5;
    };
  };

  services.jellyfin = {
    enable = true;
  };

  # Chessstack — chess opening spaced repetition trainer
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      chessstack-postgres = {
        image = "postgres:17-alpine";
        environment = {
          POSTGRES_DB = "chessstack";
          POSTGRES_USER = "chessstack";
          POSTGRES_PASSWORD = "chessstack_secret"; # change this
        };
        volumes = [
          "chessstack-pgdata:/var/lib/postgresql/data"
        ];
        extraOptions = [
          "--network=chessstack-net"
          "--health-cmd=pg_isready -U chessstack"
          "--health-interval=10s"
          "--health-timeout=5s"
          "--health-retries=5"
        ];
      };

      chessstack-app = {
        image = "ghcr.io/pvttwinkle/chessstack:latest";
        ports = [ "127.0.0.1:3000:3000" ];
        environment = {
          DATABASE_URL = "postgresql://chessstack:chessstack_secret@chessstack-postgres:5432/chessstack";
          ORIGIN = "https://chessstack.daraghhollman.duckdns.org";
          DEFAULT_USERNAME = "admin";
          DEFAULT_PASSWORD = "changeme"; # change before first boot
          REGISTRATION_MODE = "invite";
        };
        dependsOn = [ "chessstack-postgres" ];
        extraOptions = [
          "--network=chessstack-net"
        ];
      };
    };
  };

  # Create the Docker network for Chessstack containers
  systemd.services.init-chessstack-network = {
    description = "Create chessstack Docker network";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect chessstack-net \
        || ${pkgs.docker}/bin/docker network create chessstack-net
    '';
  };

  # Ensure docker is enabled
  virtualisation.docker.enable = true;

  # Backup crons
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 0 * * * daragh /home/daragh/scripts/manual-backup /mnt/data/backups/kepler-live /mnt/data/backups/kepler-archive > /mnt/data/backups/kepler-archive/log"
    ];
  };
}
