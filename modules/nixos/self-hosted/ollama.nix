{ config, lib, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cpu;

    loadModels = [ "qwen2.5-coder:7b" ];
  };

  services.open-webui = {
    enable = true;
    port = 8080;
    environment = {
      OLLAMA_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "true";
      ENABLE_SIGNUP = "false";
    };
  };
}
