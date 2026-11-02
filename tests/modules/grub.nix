{
  pkgs,
}:

let
  inherit (pkgs.lib) mkForce toUpper;

  loader = "BOOT${toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI";
in

pkgs.omnixiah.runNixOSTest {
  name = "grub-module";
  globalTimeout = 10 * 60;

  nodes.machine = {
    system.extraDependencies = mkForce [ ];

    virtualisation = {
      useBootLoader = true;
      useEFIBoot = true;
    };

    boot.loader = {
      efi.canTouchEfiVariables = false;
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        device = "nodev";
        efiRemovableBootOrder.enable = true;
      };
    };
  };

  testScript = ''
    esp = "src=$(findmnt -no SOURCE /boot); echo -d /dev/$(lsblk -dno PKNAME $src) -p $(cat /sys/class/block/$(basename $(realpath $src))/partition)"

    def fallback_entry():
        return machine.succeed(
            "efibootmgr -v | grep -iF '${loader}' | grep -F 'NixOS (/boot)' | head -n1 | cut -c5-8"
        ).strip()

    def first_entry():
        return machine.succeed("efibootmgr | sed -n 's/^BootOrder: //p' | cut -d, -f1").strip()

    def switch():
        return machine.succeed("/run/current-system/bin/switch-to-configuration boot 2>&1")

    machine.start()
    machine.wait_for_unit("multi-user.target")

    with subtest("Boots via UEFI"):
        machine.succeed("test -d /sys/firmware/efi")

    with subtest("Creates the fallback entry and puts it first"):
        switch()
        entry = fallback_entry()
        assert entry, "no firmware entry for the fallback loader"
        assert first_entry() == entry, f"BootOrder does not start with {entry}"

    with subtest("Demotes a stale entry placed first"):
        machine.succeed(f"efibootmgr -q -c $({esp}) -L decoy -l '\\EFI\\decoy\\decoy.efi'")
        assert first_entry() != entry, "decoy entry was not placed first"
        switch()
        assert first_entry() == entry, "fallback entry was not restored first"

    with subtest("Leaves a correct BootOrder untouched"):
        output = switch()
        assert "BootOrder" not in output, output

    with subtest("Boots through the fallback entry"):
        machine.shutdown()
        machine.start()
        machine.wait_for_unit("multi-user.target")
        current = machine.succeed("efibootmgr | sed -n 's/^BootCurrent: //p'").strip()
        assert current == entry, f"booted {current}, expected {entry}"
  '';
}
