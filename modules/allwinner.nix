{ lib, ... }:

let
  inherit (lib) literalExpression mkOption types;
in

{
  options.hardware.allwinner = {
    uBoot = mkOption {
      type = types.package;
      example = literalExpression "pkgs.uboot-allwinner.uBootCHIP";
      description = ''
        U-Boot build providing u-boot-sunxi-with-spl.bin. It is written to the image
        at 8 KiB for boards that boot from SD, and uploaded over USB by the FEL
        boot script for boards that do not.
      '';
    };

    chip.storage = mkOption {
      type = types.enum [
        "usb"
        "nand"
      ];
      default = "usb";
      description = ''
        Root storage of a NextThing C.H.I.P. With `usb` the system is FEL-booted
        and its root lives on USB storage. With `nand` U-Boot and the root UBI
        volume live in the on-board MLC NAND in SLC mode, written by
        `system.build.nandFlash`.
      '';
    };
  };
}
