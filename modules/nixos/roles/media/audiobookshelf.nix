{ ... }:
{
  services.audiobookshelf = {
    enable = true;
    host = "127.0.0.1";
    port = 13378;
  };

  services.caddy = {
    enable = true;

    virtualHosts = {
      "audiobookshelf.daraghhollman.duckdns.org" = {
        extraConfig = ''
          reverse_proxy localhost:13378
        '';
      };
    };
  };
}
