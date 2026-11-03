{ lib, ... }:

let
  inherit (lib) literalExpression mkOption types;
in

{
  options.hardware.allwinner.uBoot = mkOption {
    type = types.package;
    example = literalExpression "pkgs.uboot-allwinner.uBootCHIP";
    description = ''
      U-Boot build providing u-boot-sunxi-with-spl.bin. It is written to the image
      at 8 KiB for boards that boot from SD, and uploaded over USB by the FEL
      boot script for boards that do not.
    '';
  };
}
