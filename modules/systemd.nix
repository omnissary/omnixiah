{ lib, ... }:

let
  inherit (lib) mkDefault;
in

{
  systemd = {
    enableEmergencyMode = mkDefault true;
    settings.Manager.DefaultLimitCORE = mkDefault "32M";
  };

  services.journald.extraConfig = mkDefault ''
    SystemMaxUse=256M
  '';
}
