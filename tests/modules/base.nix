{
  pkgs,
}:

pkgs.omnixiah.runNixOSTest {
  name = "base-modules";
  globalTimeout = 3 * 60;

  nodes.machine = { };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("grep -qw console=ttyS0,115200 /proc/cmdline")
    machine.succeed("nix --version")
    machine.succeed("nix config show > /tmp/nix-config")
    machine.succeed("grep -q '^experimental-features = .*flakes' /tmp/nix-config")
    machine.succeed("grep -q '^connect-timeout = 5' /tmp/nix-config")
  '';
}
