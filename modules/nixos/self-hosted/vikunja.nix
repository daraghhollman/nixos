{ config, pkgs, ... }:

{
  services.vikunja = {
    enable = true;
    frontendScheme = "http";
    frontendHostname = "curie";
    port = 3456;
    settings = {
      service = {
        enableemailreminders = true;
        enableregistration = false;
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "tasks.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:3456
        '';
      };
    };
  };
}
