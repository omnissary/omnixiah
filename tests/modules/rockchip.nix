{
  inputs,
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
  inherit (inputs.nixpkgs) lib;
  inherit (lib)
    concatStringsSep
    hasInfix
    mapAttrs
    optionals
    ;
  inherit (self.lib) nixosSystem;

  hostPlatform = "aarch64-linux";

  boards = {
    orangepi-3b = {
      uBoot = "ubootOrangePi3B";
      release = "BOARD=orangepi3b";
    };
  };

  evaluate =
    name: _:
    nixosSystem {
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
    };

  evaluated = mapAttrs evaluate boards;

  boardErrors =
    name:
    let
      board = boards.${name};
      cfg = evaluated.${name}.config;
      boardPkgs = evaluated.${name}.pkgs;
      uBoot = boardPkgs.${board.uBoot};
      inherit (cfg.boot.kernelPackages) kernel;
      patches = map (patch: patch.name) kernel.kernelPatches;
      postBuild = unsafeDiscardStringContext cfg.sdImage.postBuildCommands;
    in
    map (error: "${name}: ${error}") (
      optionals (cfg.hardware.rockchip.uBoot.drvPath != uBoot.drvPath) [
        "board U-Boot is not selected"
      ]
      ++ optionals (!hasInfix (unsafeDiscardStringContext uBoot.outPath) postBuild) [
        "image does not embed the board U-Boot"
      ]
      ++ optionals (!hasInfix "seek=32768" postBuild) [
        "idbloader is not written at sector 64"
      ]
      ++ optionals (!hasInfix "seek=8388608" postBuild) [
        "u-boot.itb is not written at sector 16384"
      ]
      ++ optionals (cfg.sdImage.firmwarePartitionOffset != 8) [
        "U-Boot reserved area does not start at 8 MiB"
      ]
      ++ optionals (kernel.drvPath != boardPkgs.linuxPackages_rockchip.kernel.drvPath) [
        "Rockchip kernel is not the default"
      ]
      ++ optionals (kernel.version != boardPkgs.linuxPackages.kernel.version) [
        "Rockchip kernel does not follow the Omnixiah kernel version"
      ]
      ++ optionals (!elem "amnezia wireguard extension" patches) [
        "Rockchip kernel is missing the Omnixiah kernel patches"
      ]
      ++ optionals ((kernel.structuredExtraConfig.ARCH_ROCKCHIP or null) == null) [
        "Rockchip kernel config is missing"
      ]
      ++ optionals (!elem "console=ttyS2,1500000" cfg.boot.kernelParams) [
        "serial console is not ttyS2 at 1500000 baud"
      ]
      ++ optionals (elem "console=ttyAMA0,115200" cfg.boot.kernelParams) [
        "PL011 console is still configured"
      ]
      ++ optionals (!(cfg.systemd.services ? expand-root-partition)) [
        "root partition is not expanded on first boot"
      ]
      ++ optionals (!hasInfix "PARTN" (cfg.systemd.services.expand-root-partition.script or "")) [
        "root partition number is not read from PARTN"
      ]
      ++ optionals (cfg.boot.postBootCommands != "") [
        "first boot is handled outside the sd-image services"
      ]
      ++ optionals cfg.boot.loader.grub.enable [
        "GRUB is enabled"
      ]
      ++ optionals cfg.boot.loader.grub.efiRemovableBootOrder.enable [
        "GRUB EFI BootOrder enforcement is enabled"
      ]
      ++ optionals (!cfg.boot.loader.generic-extlinux-compatible.enable) [
        "extlinux boot loader is disabled"
      ]
      ++ optionals ((cfg.environment.etc."orangepi-release".text or null) != (board.release or null)) [
        "board release file changed"
      ]
    );

  errors = concatMap boardErrors (attrNames boards);
in

if errors != [ ] then
  throw "rockchip profile test failed:\n${concatStringsSep "\n" errors}"
else
  pkgs.writeText "omnixiah-rockchip-profile" ''
    ${concatStringsSep "\n" (attrNames boards)}
  ''
