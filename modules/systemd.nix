{ lib, ... }:

let
  inherit (lib) mkDefault;
in

{
  systemd = {
    enableEmergencyMode = mkDefault true;
    settings.Manager.DefaultLimitCORE = mkDefault "32M";
  };

  services.journald.settings.Journal.SystemMaxUse = mkDefault "256M";
}
