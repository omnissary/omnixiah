{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault mkForce mkOverride;

  inherit (config.hardware.allwinner) uBoot;
  inherit (config.boot.loader.generic-extlinux-compatible) populateCmd;
  inherit (pkgs.buildPackages) sunxi-tools writeShellScript;
in

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  boot = {
    consoleLogLevel = mkDefault 7;
    kernelPackages = mkDefault pkgs.linuxPackages_allwinner;
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
    "ttyS0,115200"
    "tty0"
  ];

  sdImage = {
    compressImage = false;
    populateFirmwareCommands = "";
    postBuildCommands = ''
      dd if="${uBoot}/u-boot-sunxi-with-spl.bin" of="$img" bs=1024 seek=8 conv=fsync,notrunc
    '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  system.build.felBoot = writeShellScript "fel-boot" ''
    exec ${sunxi-tools}/bin/sunxi-fel -v -p uboot ${uBoot}/u-boot-sunxi-with-spl.bin
  '';
}
