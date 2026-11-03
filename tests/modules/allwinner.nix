{
  pkgs,
  self,
}:

let
  inherit (builtins)
    attrNames
    concatMap
    elem
    unsafeDiscardStringContext
    ;
  inherit (pkgs) lib;
  inherit (lib)
    concatStringsSep
    hasInfix
    mapAttrs
    optionals
    ;
  inherit (self.lib) nixosSystem;

  hostPlatform = "armv7l-linux";

  boards = {
    pocketchip = {
      uBootDefconfig = "CHIP_defconfig";
      dtb = "allwinner/sun5i-r8-chip.dtb";
      overlays = [ "pocketchip" ];
    };
  };

  evaluate =
    name: _:
    (nixosSystem {
      specialArgs = {
        inherit self;
      };
      modules = [
        self.profiles.${name}
        {
          networking.hostName = name;
          nixpkgs = {
            inherit hostPlatform;
            buildPlatform = pkgs.stdenv.buildPlatform.system;
          };
        }
      ];
    }).config;

  evaluated = mapAttrs evaluate boards;

  boardErrors =
    name:
    let
      board = boards.${name};
      cfg = evaluated.${name};
      inherit (cfg.hardware.allwinner) uBoot;
      postBuild = unsafeDiscardStringContext cfg.sdImage.postBuildCommands;
      felBoot = unsafeDiscardStringContext cfg.system.build.felBoot.text;
      uBootPath = unsafeDiscardStringContext uBoot.outPath;
    in
    map (error: "${name}: ${error}") (
      optionals ((uBoot.defconfig or null) != board.uBootDefconfig) [
        "board U-Boot is not built from ${board.uBootDefconfig}"
      ]
      ++ optionals (!hasInfix "${uBootPath}/u-boot-sunxi-with-spl.bin" postBuild) [
        "image does not embed the board U-Boot"
      ]
      ++ optionals (!hasInfix "bs=1024 seek=8" postBuild) [
        "U-Boot is not written at 8 KiB"
      ]
      ++ optionals (!hasInfix "sunxi-fel" felBoot || !hasInfix uBootPath felBoot) [
        "FEL boot script does not upload the board U-Boot"
      ]
      ++ optionals (cfg.hardware.deviceTree.name != board.dtb) [
        "device tree is not ${board.dtb}"
      ]
      ++ optionals (map (overlay: overlay.name) cfg.hardware.deviceTree.overlays != board.overlays) [
        "device tree overlays changed"
      ]
      ++ optionals (!elem "console=ttyS0,115200" cfg.boot.kernelParams) [
        "serial console is not ttyS0 at 115200 baud"
      ]
      ++ optionals (elem "console=ttyAMA0,115200" cfg.boot.kernelParams) [
        "PL011 console is still configured"
      ]
      ++ optionals (!elem "usb_storage" cfg.boot.initrd.availableKernelModules) [
        "initrd cannot reach a USB root device"
      ]
      ++ optionals (hasInfix "dix" cfg.modules.update-diff.command) [
        "update diff uses dix, which is unavailable on ${hostPlatform}"
      ]
      ++ optionals cfg.boot.loader.grub.enable [
        "GRUB is enabled"
      ]
      ++ optionals (!cfg.boot.loader.generic-extlinux-compatible.enable) [
        "extlinux boot loader is disabled"
      ]
    );

  errors = concatMap boardErrors (attrNames boards);
in

if errors != [ ] then
  throw "allwinner profile test failed:\n${concatStringsSep "\n" errors}"
else
  pkgs.writeText "omnixiah-allwinner-profile" ''
    ${concatStringsSep "\n" (attrNames boards)}
  ''
