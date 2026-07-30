{ lib, ... }:

let
  inherit (lib) mkDefault;
in

{
  microvm = {
    hypervisor = "qemu";
    mem = 512;
    vcpu = 1;
    socket = "omnixiah-minimal.socket";

    shares = [
      {
        proto = "9p";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
    ];

    interfaces = [
      {
        type = "user";
        id = "qemu";
        mac = "02:00:00:00:00:01";
      }
    ];
  };

  systemd.network.networks."10-uplink" = {
    matchConfig.Type = "ether";
    networkConfig.DHCP = "yes";
    linkConfig.RequiredForOnline = "routable";
  };

  networking.firewall.allowedTCPPorts = mkDefault [ ];
}
