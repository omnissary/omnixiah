{
  pkgs,
  self,
  testing,
}:

let
  inherit (pkgs) iptables;
in

testing.runTest {
  name = "firewall-module";
  globalTimeout = 3 * 60;

  node.specialArgs = {
    inherit self;
  };

  nodes.machine = {
    imports = [
      self.nixosModules.base
    ];

    networking.firewall = {
      backend = "iptables";
      accept = [
        {
          ports = 8080;
          protocols = "tcp";
        }
      ];
      rejectSilently = [
        {
          ports = 8081;
          protocols = "tcp";
        }
      ];
      reject = [
        {
          ports = 5353;
          protocols = "udp";
        }
      ];
      drop = [
        {
          portRanges = {
            from = 9000;
            to = 9010;
          };
          protocols = "tcp";
        }
      ];
    };

    environment.systemPackages = [
      iptables
    ];
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("firewall.service")
    machine.succeed("${iptables}/bin/iptables -C nixos-fw -p tcp --dport 8080 -j nixos-fw-accept")
    machine.succeed("${iptables}/bin/ip6tables -C nixos-fw -p tcp --dport 8080 -j nixos-fw-accept")
    machine.succeed("${iptables}/bin/iptables -C nixos-fw -p tcp --dport 8081 -j nixos-fw-refuse")
    machine.succeed("${iptables}/bin/iptables -C nixos-fw -p udp --dport 5353 -j nixos-fw-log-refuse")
    machine.succeed("${iptables}/bin/iptables -C nixos-fw -p tcp --dport 9000:9010 -j DROP")
  '';
}
