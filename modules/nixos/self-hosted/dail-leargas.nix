{ config, pkgs, lib, ... }:

let
  repoUrl = "https://github.com/Lucahollman/dail-leargas";
  repoBranch = "main";

  initCommands = ''
    export PATH="${pkgs.uv}/bin:$PATH"
    ${pkgs.uv}/bin/uv run ./python/populator.py
  '';

  stateDirName = "dail-leargas";
  stateDir = "/var/lib/${stateDirName}";
  repoDir = "${stateDir}/repo";
  venvDir = "${stateDir}/venv";

  # Streamlit caches to a homedir
  homeDir = "${stateDir}/home";

  setupScript = pkgs.writeShellScript "dail-leargas-setup" ''
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

    # Build the venv from uv.lock. --frozen refuses to update the lockfile,
    # so the environment is exactly what's committed to the repo. This
    # runs BEFORE initCommands so any init/download scripts that use
    # `uv run` have a venv to run against.
    export HOME="${homeDir}"
    export PATH="${pkgs.git}/bin:$PATH"
    export UV_PROJECT_ENVIRONMENT="${venvDir}"
    export UV_PYTHON="${pkgs.python314}/bin/python3"
    export UV_PYTHON_DOWNLOADS=never

    ${pkgs.uv}/bin/uv sync --frozen --no-dev

    ${initCommands}
  '';

  runScript = pkgs.writeShellScript "dail-leargas-run" ''
    ${pkgs.uv}/bin/uv run waitress-serve --port 8502 --call app:run
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
        '';
      };
    };
  };

  systemd.services.dail-leargas-setup = {
    description = "Dail Leargas Setup";
    serviceConfig = commonHardening // {
      User = "dail-leargas";
      Group = "dail-leargas";
      Type = "oneshot";
      RemainAfterExit = true;
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

  systemd.services.dail-leargas = {
    description = "Dail Leargas App";
    after = [ "dail-leargas-setup.service" ];
    requires = [ "dail-leargas-setup.service" ];
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
              unit == "dail-leargas-setup.service") {
            return polkit.Result.YES;
          }
        }
      }
    });
  '';
}

