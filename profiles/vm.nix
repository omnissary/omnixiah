{ lib, ... }:

let
  inherit (lib) mkDefault;
in

{
  services.getty.autologinUser = mkDefault "root";
  users.allowNoPasswordLogin = mkDefault true;
}
