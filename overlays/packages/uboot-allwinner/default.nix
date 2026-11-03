_final: prev: {
  uboot-allwinner = prev.callPackage (
    { buildUBoot }:

    let
      buildSun5iUBoot =
        defconfig:
        buildUBoot {
          inherit defconfig;
          extraMeta.platforms = [ "armv7l-linux" ];
          filesToInstall = [
            "spl/sunxi-spl.bin"
            "u-boot-dtb.bin"
            "u-boot-sunxi-with-spl.bin"
          ];
        };
    in
    {
      uBootCHIP = buildSun5iUBoot "CHIP_defconfig";
    }
  ) { };
}
