{ config, pkgs, lib, ... }:

let
  repoUrl = "https://github.com/Lucahollman/dail-leargas";
  repoBranch = "main";

  stateDirName = "dail-leargas";
  stateDir = "/var/lib/${stateDirName}";
  repoDir = "${stateDir}/repo";
  venvDir = "${stateDir}/venv";

  # Streamlit caches to a homedir
  homeDir = "${stateDir}/home";

  setupScript = pkgs.writeShellScript "dail-leargas-updater" ''
    # Clone if repo doesn't exist
    if [ ! -d "${repoDir}/.git" ]; then
      ${pkgs.git}/bin/git clone --branch "${repoBranch}" \
        "${repoUrl}" "${repoDir}"
    else
      ${pkgs.git}/bin/git -C "${repoDir}" fetch origin "${repoBranch}"
      ${pkgs.git}/bin/git -C "${repoDir}" reset --hard "origin/${repoBranch}"
    fi

    cd "${repoDir}"
    mkdir -p "${homeDir}"

    export HOME="${homeDir}"
    export PATH="${pkgs.git}/bin:$PATH"
    export UV_PROJECT_ENVIRONMENT="${venvDir}"
    export UV_PYTHON="${pkgs.python314}/bin/python3"
    export UV_PYTHON_DOWNLOADS=never

    ${pkgs.uv}/bin/uv sync --frozen --no-dev

    export PATH="${pkgs.uv}/bin:$PATH"
    ${pkgs.uv}/bin/uv run ./python/populator.py
  '';

  runScript = pkgs.writeShellScript "dail-leargas-run" ''
    cd "${repoDir}"
    exec "${venvDir}/bin/waitress-serve" \
      --port=8502 \
      --call app:run
  '';

  commonHardening = {
    NoNewPrivileges = true;
    ProtectHome = true;
    PrivateTmp = true;
  };

in
{
  services.caddy = {
    enable = true;

    virtualHosts = {
      "https://dail-leargas.duckdns.org" = {
        extraConfig = ''
          reverse_proxy localhost:8502
          log {
            output file /var/log/caddy/dail-leargas.duckdns.org.log
            format json
          }
        '';
      };
    };
  };

  systemd.services.dail-leargas-updater = {
    description = "Dail Leargas Updater";
    serviceConfig = commonHardening // {
      User = "dail-leargas";
      Group = "dail-leargas";
      Type = "oneshot";
      StateDirectory = stateDirName;
      WorkingDirectory = stateDir;
      ExecStart = "${setupScript}";
      ReadWritePaths = [ stateDir ];
      Environment = [
        "HOME=${homeDir}"
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
      ];
    };
  };

  systemd.timers.dail-leargas-updater = {
    description = "Dail Leargas update timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Runs at midnight every weekday
      OnCalendar = "0 0 * * 2-6";
      Persistent = true; #
      Unit = "dail-leargas-updater.service";
    };
  };

  systemd.services.dail-leargas = {
    description = "Dail Leargas App";
    after = [ "dail-leargas-updater.service" ];
    requires = [ "dail-leargas-updater.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = commonHardening // {
      User = "dail-leargas";
      Group = "dail-leargas";
      Type = "simple";
      StateDirectory = stateDirName;
      WorkingDirectory = repoDir;
      Environment = [
        "HOME=${homeDir}"
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
      ];
      ExecStart = "${runScript}";
      Restart = "on-failure";
      RestartSec = 30;
      ReadWritePaths = [ repoDir venvDir homeDir ];
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      IPAddressDeny = [ "any" ];
      IPAddressAllow = [ "localhost" ];
    };
  };

  users.groups.dail-leargas = { };

  users.users.dail-leargas = {
    isSystemUser = true;
    group = "dail-leargas";
  };

  security.polkit.enable = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("dail-leargas")) {
        var actionId = action.id;

        if (actionId == "org.freedesktop.systemd1.manage-units" ||
            actionId == "org.freedesktop.systemd1.manage-unit-files") {
          var unit = action.lookup("unit");

          if (unit == "dail-leargas.service" ||
              unit == "dail-leargas-updater.service") {
            return polkit.Result.YES;
          }
        }
      }
    });
  '';
}

