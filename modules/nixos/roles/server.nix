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

  # Cron to update ip for DuckDNS
  systemd.services.duckdns = {
    description = "DuckDNS IP updater";
    after = [ "network-online.target" "agenix.service" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "duckdns-update" ''
        TOKEN=$(cat ${config.age.secrets.duckdns-token.path})
        DOMAIN="YOURSUBDOMAIN"
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

      "immich.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy localhost:2283
        '';
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };
}
