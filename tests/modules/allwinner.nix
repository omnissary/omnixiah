{
  pkgs,
  self,
}:

let
  inherit (builtins)
    any
    attrNames
    concatLists
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
    chip = {
      uBootDefconfig = "CHIP_defconfig";
      dtb = "allwinner/sun5i-r8-chip.dtb";
      overlays = [ ];
      pocketchip = false;
    };
    pocketchip = {
      uBootDefconfig = "CHIP_defconfig";
      dtb = "allwinner/sun5i-r8-chip.dtb";
      overlays = [ "pocketchip" ];
      pocketchip = true;
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
      inherit (evaluated.${name}) options;
      cfg = evaluated.${name}.config;
      firmware = concatLists options.hardware.firmware.definitions;
      inherit (cfg.hardware.allwinner) uBoot;
      postBuild = unsafeDiscardStringContext cfg.sdImage.postBuildCommands;
      felBoot = unsafeDiscardStringContext cfg.system.build.felBoot.text;
      uBootPath = unsafeDiscardStringContext uBoot.outPath;
      inherit (cfg.boot.kernelPackages) kernel;
      patches = map (patch: patch.name) kernel.kernelPatches;
      udevRules = unsafeDiscardStringContext cfg.services.udev.extraRules;
      touchCalibrated =
        hasInfix ''DRIVERS=="sun4i-ts"'' udevRules && hasInfix "LIBINPUT_CALIBRATION_MATRIX" udevRules;
      xkbPocketchip = cfg.services.xserver.xkb.extraLayouts ? pocketchip;
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
      ++ optionals ((kernel.structuredExtraConfig.BT_HCIUART_RTL or null) == null) [
        "kernel lacks Realtek HCI UART support for the RTL8723BS Bluetooth"
      ]
      ++ optionals (!elem "amnezia wireguard extension" patches) [
        "Allwinner kernel is missing the Omnixiah kernel patches"
      ]
      ++ optionals (!elem "fw_devlink=permissive" cfg.boot.kernelParams) [
        "display waits for the fw_devlink deferred-probe timeout"
      ]
      ++
        optionals (!hasInfix "options r8723bs rtw_power_mgnt=0 rtw_ips_mode=0" cfg.boot.extraModprobeConfig)
          [
            "r8723bs firmware power saving is not disabled"
          ]
      ++ optionals (!any (package: (package.name or "") == "rtl8723bs-firmware") firmware) [
        "RTL8723BS firmware is not installed"
      ]
      ++ optionals (cfg.networking.networkmanager.wifi.macAddress != "permanent") [
        "NetworkManager randomizes the RTL8723BS MAC address"
      ]
      ++ optionals ((cfg.services.logind.settings.Login.HandlePowerKey or null) != "ignore") [
        "logind powers off on a short power key press"
      ]
      ++ optionals (touchCalibrated != board.pocketchip) [
        "touchscreen calibration does not match the board"
      ]
      ++ optionals (xkbPocketchip != board.pocketchip) [
        "PocketCHIP keyboard layout does not match the board"
      ]
      ++ optionals (board.pocketchip && !hasInfix "pocketchip" (toString cfg.console.keyMap)) [
        "PocketCHIP console keymap is not loaded"
      ]
      ++
        optionals
          (
            board.pocketchip
            && !(cfg.services.upower.enable && cfg.services.upower.criticalPowerAction == "PowerOff")
          )
          [
            "battery critical level does not power off"
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
