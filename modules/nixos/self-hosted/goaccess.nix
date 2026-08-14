{ config, pkgs, lib, ... }:

let
  logDir = "/var/log/caddy";
  statsDir = "/var/www/stats";
  geoipDir = "/var/lib/GeoIP";

  # List every site you want tracked. Each one gets its own log file
  # and its own GoAccess report.
  sites = [
    "bepicolombo.daraghhollman.duckdns.org"
    "dail-leargas.duckdns.org"
  ];
  # Script that regenerates one HTML report per site, plus an index page.
  goaccessScript = pkgs.writeShellScript "goaccess-reports" ''
    mkdir -p ${statsDir}

    index="${statsDir}/index.html.tmp"
    {
      echo "<html><head><title>Site stats</title></head><body>"
      echo "<h1>Site stats</h1><ul>"
    } > "$index"

    ${lib.concatMapStringsSep "\n" (site: ''
      if [ -f "${logDir}/${site}.log" ]; then
        ${pkgs.goaccess}/bin/goaccess "${logDir}/${site}.log" \
          --log-format=CADDY \
          -o "${statsDir}/${site}.html" \
          --ignore-crawlers \
          --geoip-database=${geoipDir}/GeoLite2-City.mmdb \
          -a
        echo "<li><a href=\"${site}.html\">${site}</a></li>" >> "$index"
      fi
    '') sites}

    echo "</ul></body></html>" >> "$index"
    mv "$index" "${statsDir}/index.html"
  '';
in
{
  age.secrets."GeoIP.conf" = {
    file = ../../../secrets/geoip.env.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };

  services.caddy = {
    enable = true;

    virtualHosts = {
      "localhost:8081" = {
        extraConfig = ''
          root * ${statsDir}
          file_server
        '';
      };
    };
  };

  # Make sure the caddy user can write logs and the goaccess job can read them.
  systemd.services.caddy.serviceConfig.ReadWritePaths = [ logDir ];

  system.activationScripts.caddyLogDir = ''
    mkdir -p ${logDir}
    chown caddy:caddy ${logDir}
  '';

  environment.systemPackages = [
    pkgs.goaccess
    pkgs.geoipupdate
    pkgs.goaccess
  ];

  systemd.services.geoip-update = {
    description = "Update GeoLite2 databases via geoipupdate";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.geoipupdate}/bin/geoipupdate -f ${config.age.secrets."GeoIP.conf".path} -d ${geoipDir}";
      User = "root"; # needs to read the agenix secret and write to geoipDir
    };
  };
  systemd.timers.geoip-update = {
    description = "Run geoipupdate daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1d";
      Unit = "geoip-update.service";
    };
  };
  system.activationScripts.geoipDir = ''
    mkdir -p ${geoipDir}
    chown root:caddy ${geoipDir}
    chmod 750 ${geoipDir}
  '';

  # GoAccess report generation, on a timer
  systemd.services.goaccess-reports = {
    description = "Generate GoAccess HTML reports for all Caddy sites";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${goaccessScript}";
      User = "caddy"; # needs read access to /var/log/caddy
    };
  };

  systemd.timers.goaccess-reports = {
    description = "Run goaccess-reports every 5 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "1m";
      Unit = "goaccess-reports.service";
    };
  };

  system.activationScripts.statsDir = ''
    mkdir -p ${statsDir}
    chown caddy:caddy ${statsDir}
  '';
}
