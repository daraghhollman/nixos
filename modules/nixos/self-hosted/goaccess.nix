{ config, pkgs, lib, ... }:

let
  logDir = "/var/log/caddy";
  statsDir = "/var/www/stats";

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
          -a
        echo "<li><a href=\"${site}.html\">${site}</a></li>" >> "$index"
      fi
    '') sites}

    echo "</ul></body></html>" >> "$index"
    mv "$index" "${statsDir}/index.html"
  '';
in
{
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

  # GoAccess report generation, on a timer
  environment.systemPackages = [ pkgs.goaccess ];

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
