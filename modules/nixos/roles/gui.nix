/*
  Config to enable a machine to enable gui
*/

{ config, pkgs, lib, ... }:

{

  options = {
    roles.gui.defaultSession = lib.mkOption {
      type = lib.types.str;
      default = "sway";
      description = "The command greetd will launch as the default session";
    };
  };

  config = {
    # GUI Options
    programs.sway.enable = true;

    # Display Manager
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${config.roles.gui.defaultSession}";
          user = "greeter";
        };
      };
    };

    # Seat management — required for Wayland compositors to access input/display hardware
    services.seatd.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    users.users.daragh.extraGroups = [ "video" "input" "seat" ];


  };
}
