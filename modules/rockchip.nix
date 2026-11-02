{ lib, ... }:

let
  inherit (lib) literalExpression mkOption types;
in

{
  options.hardware.rockchip.uBoot = mkOption {
    type = types.package;
    example = literalExpression "pkgs.uboot-rockchip.uBootOrangePi3B";
    description = ''
      U-Boot build written to the image ahead of the first partition. It provides
      either a combined u-boot-rockchip.bin or idbloader.img with u-boot.itb.
    '';
  };
}
