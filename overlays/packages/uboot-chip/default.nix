_self: super: {
  uboot-chip = super.callPackage (
    {
      lib,
      fetchFromGitHub,
      buildUBoot,
      ...
    }:

    let
      buildChipUBoot =
        { defconfig }:
        let
          src = fetchFromGitHub {
            owner = "u-boot";
            repo = "u-boot";
            rev = "v2025.10";
            hash = "sha256-9y21xYwJ/ATFikCRuhalKjAhpRHmOZv6a7GDkLhbon4=";
          };
          version = "v2025.10";
        in
        buildUBoot {
          inherit src defconfig;
          inherit version;
          filesToInstall = [ "u-boot-sunxi-with-spl.bin" ];
          extraConfig = ''
            CONFIG_NAND=y
            CONFIG_SYS_NAND_SELF_INIT=y
            CONFIG_NAND_SUNXI=y
          '';
          extraMeta = {
            platforms = [ "armv7l-linux" ];
            license = lib.licenses.gpl2Plus;
          };
        };
    in
    {
      uBootChip = buildChipUBoot { defconfig = "CHIP_defconfig"; };
    }
  ) { };
}
