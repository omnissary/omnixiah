{
  pkgs,
}:

pkgs.omnixiah.runNixOSTest {
  name = "base-profile";
  globalTimeout = 3 * 60;

  nodes.machine =
    { pkgs, ... }:
    {
      assertions = [
        {
          assertion = pkgs ? omnixiah;
          message = "The base profile must apply the Omnixiah overlay.";
        }
      ];
    };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.succeed("grep -qw console=tty0 /proc/cmdline")
    machine.succeed("nix --version")
    machine.succeed("nix config show > /tmp/nix-config")
    machine.succeed("grep -q '^experimental-features = .*flakes' /tmp/nix-config")
    machine.succeed("grep -q '^connect-timeout = 5' /tmp/nix-config")
  '';
}
