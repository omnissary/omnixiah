{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.omnixiah.sysctl;
in

{
  options.omnixiah.sysctl.enable = mkEnableOption "Omnixiah sysctl defaults" // {
    default = true;
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
      # https://security-tracker.debian.org/tracker/CVE-2026-98432
      "net.mptcp.enabled" = 0;
      "net.ipv4.tcp_migrate_req" = 0;
    };
  };
}
