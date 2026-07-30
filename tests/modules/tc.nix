{
  self,
  testing,
}:

testing.runTest {
  name = "tc-module";
  globalTimeout = 3 * 60;

  node.specialArgs = {
    inherit self;
  };

  nodes.machine = {
    imports = [
      self.nixosModules.base
    ];

    networking.tc.shaper = {
      enable = true;
      interfaces.eth1 = {
        disableOffloading = false;
        egress.bandwidth = "1mbit";
      };
    };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("sys-subsystem-net-devices-eth1.device")
    machine.wait_for_unit("tc-shaper-eth1.service")
    machine.succeed("tc qdisc show dev eth1 | grep -q htb")
  '';
}
