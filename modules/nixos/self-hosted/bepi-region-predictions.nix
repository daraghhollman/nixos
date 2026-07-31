{ config, pkgs, lib, ... }:

let
  repoUrl = "https://github.com/daraghhollman/bepi-streamlit-dashboard";
  repoBranch = "main";

  initCommands = ''
    export PATH="${pkgs.uv}/bin:$PATH"
    ${pkgs.uv}/bin/uv run ./init.py
  '';

  appEntrypoint = "app.py";
  listenPort = 8501;
  listenAddress = "127.0.0.1";

  stateDirName = "streamlit-app";
  stateDir = "/var/lib/${stateDirName}";
  repoDir = "${stateDir}/repo";
  venvDir = "${stateDir}/venv";

  # Streamlit caches to a homedir
  homeDir = "${stateDir}/home";

  setupScript = pkgs.writeShellScript "streamlit-app-setup" ''
    # Clone if repo doesn't exist
    if [ ! -d "${repoDir}/.git" ]; then
      ${pkgs.git}/bin/git clone --branch "${repoBranch}" --depth 1 --recurse-submodules --shallow-submodules \
        "${repoUrl}" "${repoDir}"
    else
      ${pkgs.git}/bin/git -C "${repoDir}" fetch origin "${repoBranch}"
      ${pkgs.git}/bin/git -C "${repoDir}" reset --hard "origin/${repoBranch}"
      ${pkgs.git}/bin/git -C "${repoDir}" submodule sync --recursive
      ${pkgs.git}/bin/git -C "${repoDir}" submodule update --init --recursive
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

  runScript = pkgs.writeShellScript "streamlit-app-run" ''
    cd "${repoDir}"
    exec "${venvDir}/bin/streamlit" run "${appEntrypoint}" \
      --server.port=${toString listenPort} \
      --server.address=${listenAddress} \
      --server.headless=true
  '';

  commonHardening = {
    NoNewPrivileges = true;
    ProtectHome = true;
    PrivateTmp = true;
  };

in

{
  systemd.services.streamlit-app-setup = {
    description = "Clone and initialize the streamlit app repository";
    serviceConfig = commonHardening // {
      User = "bepi";
      Group = "bepi";
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = stateDirName; # creates/owns /var/lib/streamlit-app
      WorkingDirectory = stateDir;
      ExecStart = "${setupScript}";
      ReadWritePaths = [ stateDir ];
      Environment = [
        "HOME=${homeDir}"
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
      ];
    };
  };

  systemd.services.streamlit-app = {
    description = "Streamlit web application";
    after = [ "streamlit-app-setup.service" ];
    requires = [ "streamlit-app-setup.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = commonHardening // {
      User = "bepi";
      Group = "bepi";
      Type = "simple";
      StateDirectory = stateDirName;
      WorkingDirectory = repoDir;
      Environment = [
        "HOME=${homeDir}"
        "STREAMLIT_BROWSER_GATHER_USAGE_STATS=false"
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
      ];
      ExecStart = "${runScript}";
      Restart = "on-failure";
      RestartSec = 5;
      ReadWritePaths = [ repoDir venvDir homeDir ];
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      IPAddressDeny = [ "any" ];
      IPAddressAllow = [ "localhost" ];
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "https://bepicolombo.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy localhost:8501
        '';
      };
    };
  };

  users.groups.bepi = { };

  users.users.bepi = {
    isSystemUser = true;
    group = "bepi";
  };
}
