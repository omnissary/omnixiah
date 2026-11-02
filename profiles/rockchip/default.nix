{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  inherit (lib) mkBefore mkDefault;

  inherit (config.hardware.rockchip) uBoot;
  inherit (config.boot.loader.generic-extlinux-compatible) populateCmd;
  nix = config.nix.package.out;

  idbloaderOffset = 64;
  ubootOffset = 16384;
  ubootSize = 16384;

  seek = offset: toString (offset * 512);
  dd = "conv=fsync,notrunc bs=16M iflag=direct,count_bytes,skip_bytes oflag=direct,seek_bytes";
in

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  boot = {
    consoleLogLevel = mkDefault 7;
    kernelPackages = mkDefault pkgs.linuxPackages_rockchip;
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    postBootCommands = mkBefore ''
      if [ -f /nix-path-registration ]; then
        set -euo pipefail
        set -x
        rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
        bootDevice=$(lsblk -npo PKNAME $rootPart)
        partNum=2

        echo ",+," | sfdisk -N$partNum --no-reread $bootDevice
        ${pkgs.parted}/bin/partprobe
        ${pkgs.e2fsprogs}/bin/resize2fs $rootPart

        ${nix}/bin/nix-store --load-db < /nix-path-registration

        touch /etc/NIXOS
        ${nix}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

        rm -f /nix-path-registration
      fi
    '';
  };

  modules.boot.consoles = mkDefault [
    "ttyS2,1500000"
    "tty0"
  ];

  sdImage = {
    compressImage = false;
    expandOnBoot = false;

    firmwarePartitionOffset = ubootOffset / 2048;
    firmwareSize = ubootSize / 2048;
    populateFirmwareCommands = "";
    postBuildCommands = ''
      sfdisk --part-type "$img" 1 DA
      if [ -e "${uBoot}/u-boot-rockchip.bin" ]; then
        dd if="${uBoot}/u-boot-rockchip.bin" of="$img" seek=${seek idbloaderOffset} ${dd}
      else
        dd if="${uBoot}/idbloader.img" of="$img" seek=${seek idbloaderOffset} ${dd}
        dd if="${uBoot}/u-boot.itb" of="$img" seek=${seek ubootOffset} ${dd}
      fi
      sfdisk -d "$img"
    '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
