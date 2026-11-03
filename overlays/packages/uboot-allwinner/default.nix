_final: prev: {
  uboot-allwinner = prev.callPackage (
    { buildUBoot }:

    let
      buildSun5iUBoot =
        defconfig: args:
        buildUBoot (
          {
            inherit defconfig;
            extraMeta.platforms = [ "armv7l-linux" ];
            filesToInstall = [
              "spl/sunxi-spl.bin"
              "u-boot-dtb.bin"
              "u-boot-sunxi-with-spl.bin"
            ];
          }
          // args
        );
    in
    {
      uBootCHIP = buildSun5iUBoot "CHIP_defconfig" { };

      # Untested on hardware: the x-chip-uboot SLC-on-MLC patches are rebased
      # from v2022.01, so reading the MLC NAND and the on-flash bad block
      # table agreeing with the kernel (nand-on-flash-bbt in
      # profiles/allwinner/chip/nand.dts) are unverified.
      uBootCHIPNand = buildSun5iUBoot "CHIP_defconfig" {
        extraPatches = [
          ./chip-nand-slc-emulation.patch
          ./chip-fastboot-nand-slc.patch
          ./chip-nand-spl-dma.patch
          ./chip-w1-read-address.patch
        ];
        extraConfig = ''
          CONFIG_CMD_MTDPARTS=y
          CONFIG_CMD_UBI=y
          CONFIG_CMD_UBIFS=y
          CONFIG_DM_MTD=y
          CONFIG_FASTBOOT_FLASH=y
          CONFIG_FASTBOOT_FLASH_NAND=y
          CONFIG_MTD=y
          CONFIG_MTDIDS_DEFAULT="nand0=nand0"
          CONFIG_MTDPARTS_DEFAULT="nand0:0x400000(SPL),0x400000(SPL.backup),0x400000(U-Boot),0x400000(U-Boot.backup),-(rootfs)slc"
          CONFIG_MTD_RAW_NAND=y
          CONFIG_NAND_SUNXI_SPL_ECC_SIZE=512
          CONFIG_SYS_NAND_BLOCK_SIZE=0x400000
          CONFIG_SYS_NAND_OOBSIZE=0x680
          CONFIG_SYS_NAND_PAGE_SIZE=0x4000
          CONFIG_SYS_NAND_U_BOOT_OFFS_REDUND=0xc00000
          CONFIG_SYS_NAND_USE_FLASH_BBT=y
          CONFIG_UBI_SILENCE_MSG=y
          CONFIG_BOOTCOMMAND="run bootcmd_fel; if ubi part rootfs && ubifsmount ubi0:rootfs; then sysboot ubi 0 any ''${scriptaddr} /boot/extlinux/extlinux.conf; fi; run distro_bootcmd"
        '';
        filesToInstall = [
          ".config"
          "spl/sunxi-spl.bin"
          "u-boot-dtb.bin"
          "u-boot-sunxi-with-spl.bin"
        ];
      };
    }
  ) { };
}
