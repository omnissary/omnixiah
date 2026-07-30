{ lib, ... }:

let
  inherit (lib) mkDefault;
in

{
  services.timesyncd = {
    enable = mkDefault true;
    servers = mkDefault [
      "time.cloudflare.com"
      "time.google.com"
      "pool.ntp.org"
    ];
  };
}
