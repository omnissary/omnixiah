{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    escapeShellArg
    escapeShellArgs
    mkEnableOption
    mkIf
    toUpper
    unique
    ;

  cfg = config.boot.loader.grub;

  esps = unique (
    map (
      boot: if boot.efiSysMountPoint == null then boot.path else boot.efiSysMountPoint
    ) cfg.mirroredBoots
  );
  fallback = "\\EFI\\BOOT\\BOOT${toUpper pkgs.stdenv.hostPlatform.efiArch}.EFI";

  efiBootOrder = pkgs.writeShellApplication {
    name = "grub-efi-boot-order";
    runtimeInputs = with pkgs; [
      coreutils
      efibootmgr
      gnugrep
      gnused
      util-linux
    ];
    text = ''
      fallback=${escapeShellArg fallback}

      if [ ! -d /sys/firmware/efi/efivars ]; then
        echo "grub-efi-boot-order: not booted via EFI, skipping" >&2
        exit 0
      fi

      entry_for() {
        efibootmgr -v \
          | grep -E '^Boot[0-9A-Fa-f]{4}' \
          | grep -iF "$1" \
          | grep -iF "$fallback" \
          | head -n1 \
          | cut -c5-8 || true
      }

      want=()
      for esp in "$@"; do
        src=$(findmnt -no SOURCE --mountpoint "$esp" || true)
        uuid=$(if [ -n "$src" ]; then lsblk -dno PARTUUID "$src"; fi || true)
        disk=$(if [ -n "$src" ]; then lsblk -dno PKNAME "$src"; fi || true)
        if [ -z "$uuid" ] || [ -z "$disk" ]; then
          echo "grub-efi-boot-order: cannot resolve partition for $esp, skipping" >&2
          continue
        fi

        num=$(entry_for "$uuid")
        if [ -z "$num" ]; then
          part=$(cat "/sys/class/block/$(basename "$(realpath "$src")")/partition")
          echo "grub-efi-boot-order: creating entry for $fallback on /dev/$disk partition $part" >&2
          efibootmgr -q -c -d "/dev/$disk" -p "$part" -L "NixOS ($esp)" -l "$fallback"
          num=$(entry_for "$uuid")
        fi
        if [ -z "$num" ]; then
          echo "grub-efi-boot-order: no entry for $fallback on $esp after create" >&2
          exit 1
        fi
        want+=("$num")
      done

      [ "''${#want[@]}" -gt 0 ] || exit 0

      current=$(efibootmgr | sed -n 's/^BootOrder: //p')
      order=("''${want[@]}")
      for n in ''${current//,/ }; do
        keep=1
        for w in "''${want[@]}"; do
          [ "$n" = "$w" ] && keep=0
        done
        [ "$keep" = 1 ] && order+=("$n")
      done
      new=$(IFS=,; echo "''${order[*]}")

      if [ "$new" != "$current" ]; then
        echo "grub-efi-boot-order: BootOrder $current -> $new" >&2
        efibootmgr -q -o "$new"
      fi
    '';
  };
in

{
  # A generic fix for something nixpkgs does not handle: GRUB in removable mode
  # with no firmware access never touches firmware boot entries, so stale ones
  # can win after an upgrade.
  options.boot.loader.grub.efiRemovableBootOrder.enable = mkEnableOption ''
    keeping a firmware boot entry for the removable EFI fallback loader on every
    ESP first in BootOrder
  '';

  config = mkIf cfg.efiRemovableBootOrder.enable {
    assertions = [
      {
        assertion = cfg.enable && cfg.efiSupport && cfg.efiInstallAsRemovable;
        message = "boot.loader.grub.efiRemovableBootOrder requires boot.loader.grub with efiSupport and efiInstallAsRemovable";
      }
    ];

    boot.loader.grub.extraInstallCommands = ''
      ${efiBootOrder}/bin/grub-efi-boot-order ${escapeShellArgs esps} \
        || echo "warning: failed to enforce EFI BootOrder for ${fallback}, check efibootmgr -v before rebooting" >&2
    '';
  };
}
