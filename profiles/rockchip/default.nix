{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault mkForce mkOverride;

  inherit (config.hardware.rockchip) uBoot;
  inherit (config.boot.loader.generic-extlinux-compatible) populateCmd;

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
  };

  hardware = {
    enableAllHardware = mkForce false;
    enableAllFirmware = mkOverride 900 false;
    enableRedistributableFirmware = mkOverride 900 false;
  };

  modules.boot.consoles = mkDefault [
    "ttyS2,1500000"
    "tty0"
  ];

  sdImage = {
    compressImage = false;

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
