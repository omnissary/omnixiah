{
  pkgs,
}:

let
  inherit (pkgs) wireguard-tools;

  settings = [
    "jc 3 jmin 40 jmax 80"
    "s1 16 s2 32 s3 16 s4 16"
    "h1 100-110 h2 200-210 h3 300-310 h4 400-410"
    "i1 '<b 0xd1><r 5>' i2 '<c>' i3 '<t>'"
    "content-padding-addition 4-12"
    "rekey-timeout 5-6 reject-after-time 60-61 keepalive-timeout 10-11"
    "random-trailers on disable-cookies on"
  ];

  mkNode = _: {
    networking.firewall.enable = false;

    environment.systemPackages = [
      wireguard-tools
    ];
  };
in

pkgs.omnixiah.runNixOSTest {
  name = "wireguard-amnezia";
  globalTimeout = 20 * 60;

  nodes = {
    alice = mkNode 1;
    bob = mkNode 2;
  };

  testScript = ''
    import shlex

    settings = ${builtins.toJSON (builtins.concatStringsSep " " settings)}

    start_all()
    alice.wait_for_unit("multi-user.target")
    bob.wait_for_unit("multi-user.target")

    # The patched kernel has to be the one under test.
    for node in (alice, bob):
        node.succeed("modprobe wireguard")
        node.succeed("wg --version")

    keys = {}
    for name, node in (("alice", alice), ("bob", bob)):
        private = node.succeed("wg genkey").strip()
        node.succeed(f"install -m600 /dev/null /root/private && printf %s {shlex.quote(private)} > /root/private")
        keys[name] = node.succeed("wg pubkey < /root/private").strip()

    hpkey = alice.succeed("wg genkey").strip()
    otherkey = alice.succeed("wg genkey").strip()
    for node in (alice, bob):
        node.succeed(f"install -m600 /dev/null /root/hp && printf %s {shlex.quote(hpkey)} > /root/hp")
        node.succeed(f"install -m600 /dev/null /root/hp-other && printf %s {shlex.quote(otherkey)} > /root/hp-other")

    peers = {
        "alice": ("10.100.0.1/24", keys["bob"], "192.168.1.2:51820"),
        "bob": ("10.100.0.2/24", keys["alice"], "192.168.1.1:51820"),
    }
    for name, node in (("alice", alice), ("bob", bob)):
        address, peer, endpoint = peers[name]
        node.succeed("ip link add wg0 type wireguard")
        node.succeed(f"ip address add {address} dev wg0")
        node.succeed(
            "wg set wg0 listen-port 51820 private-key /root/private "
            f"header-protection-key /root/hp {settings}"
        )
        node.succeed(f"wg set wg0 peer {peer} allowed-ips 10.100.0.0/24 endpoint {endpoint}")
        node.succeed("ip link set wg0 up")

    with subtest("the obfuscation settings round-trip through the kernel"):
        config = alice.succeed("wg showconf wg0")
        for line in (
            "Jc = 3",
            "Jmin = 40",
            "Jmax = 80",
            "S1 = 16",
            "S4 = 16",
            "H1 = 100-110",
            "H4 = 400-410",
            "I1 = <b 0xd1><r 5>",
            "ContentPaddingAddition = 4-12",
            "RekeyTimeout = 5-6",
            "RandomTrailers = on",
            "DisableCookies = on",
            f"HeaderProtectionKey = {hpkey}",
        ):
            assert line in config, f"{line!r} missing from:\n{config}"

    with subtest("traffic passes with matching obfuscation on both peers"):
        alice.wait_until_succeeds("ping -W 2 -c 1 10.100.0.2", timeout=30)

    with subtest("a one-sided header protection key stops traffic"):
        bob.succeed("wg set wg0 header-protection-key /root/hp-other")
        alice.fail("ping -W 2 -c 3 10.100.0.2")
        bob.succeed("wg set wg0 header-protection-key /root/hp")
        alice.wait_until_succeeds("ping -W 2 -c 1 10.100.0.2", timeout=30)

    with subtest("a rejected setting leaves the live configuration alone"):
        before = alice.succeed("wg showconf wg0")
        alice.fail("wg set wg0 rekey-timeout 0-7")
        alice.fail("wg set wg0 jmin 100 jmax 50")
        alice.fail("wg set wg0 h1 205-215")
        assert alice.succeed("wg showconf wg0") == before, "a rejected update changed the configuration"

    # The default kernel carries no KASAN or lockdep, so this only catches
    # hard failures; the in-tree selftest covers the debug build.
    with subtest("the kernel did not crash"):
        for node in (alice, bob):
            dmesg = node.succeed("dmesg")
            for marker in ("BUG:", "Oops", "general protection fault", "KASAN:"):
                assert marker not in dmesg, f"{marker} in dmesg:\n{dmesg}"
  '';
}
