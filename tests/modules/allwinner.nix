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
    lessThan
    unsafeDiscardStringContext
    ;
  inherit (pkgs) lib;
  inherit (lib)
    concatStringsSep
    hasInfix
    mapAttrs
    mkDefault
    optionals
    sort
    ;
  inherit (self.lib) nixosSystem;

  hostPlatform = "armv7l-linux";

  boards = {
    chip = {
      profile = "chip";
      storage = "usb";
      uBootDefconfig = "CHIP_defconfig";
      dtb = "sun5i-r8-chip.dtb";
      overlays = [ ];
      pocketchip = false;
    };
    pocketchip = {
      profile = "pocketchip";
      storage = "usb";
      uBootDefconfig = "CHIP_defconfig";
      dtb = "sun5i-r8-chip.dtb";
      overlays = [ "pocketchip" ];
      pocketchip = true;
    };
    pocketchip-nand = {
      profile = "pocketchip";
      storage = "nand";
      uBootDefconfig = "CHIP_defconfig";
      dtb = "sun5i-r8-chip.dtb";
      overlays = [
        "chip-nand"
        "pocketchip"
      ];
      pocketchip = true;
    };
  };

  evaluate =
    name: board:
    nixosSystem {
      specialArgs = {
        inherit self;
      };
      modules = [
        self.profiles.${board.profile}
        {
          hardware.allwinner.chip.storage = board.storage;
          networking.hostName = name;
          hardware = {
            enableAllFirmware = mkDefault true;
            enableRedistributableFirmware = mkDefault true;
          };
          users.allowNoPasswordLogin = true;
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
      nand = board.storage == "nand";
      nandFlash = unsafeDiscardStringContext (cfg.system.build.nandFlash.text or "");
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
      ++
        optionals
          (sort lessThan (map (overlay: overlay.name) cfg.hardware.deviceTree.overlays) != board.overlays)
          [
            "device tree overlays changed"
          ]
      ++ optionals (!elem "console=ttyS0,115200" cfg.boot.kernelParams) [
        "serial console is not ttyS0 at 115200 baud"
      ]
      ++ optionals (elem "console=ttyAMA0,115200" cfg.boot.kernelParams) [
        "PL011 console is still configured"
      ]
      ++ optionals (!elem "g_ether" cfg.boot.kernelModules) [
        "USB Ethernet gadget is not loaded on the OTG port"
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
      ++ optionals (cfg.services.journald.settings.Journal.Storage != "volatile") [
        "journald writes the journal to flash"
      ]
      ++ optionals (!cfg.boot.tmp.useTmpfs) [
        "/tmp is on flash"
      ]
      ++ optionals cfg.services.fwupd.enable [
        "fwupd is enabled on a board without UEFI or LVFS devices"
      ]
      ++ optionals cfg.services.speechd.enable [
        "speech-dispatcher pulls ffmpeg, SDL and espeak onto the flash"
      ]
      ++ optionals (cfg.systemd.package.drvPath != evaluated.${name}.pkgs.systemd.drvPath) [
        "systemd.package and pkgs.systemd differ, the image ships two systemd copies"
      ]
      ++ optionals cfg.services.pipewire.enable [
        "PipeWire pulls ffmpeg onto the flash"
      ]
      ++ optionals cfg.fonts.enableDefaultPackages [
        "default fonts pull Noto CJK onto the flash"
      ]
      ++ optionals cfg.services.xserver.desktopManager.wallpaper.enable [
        "X session sets the wallpaper with feh, which pulls ghostscript"
      ]
      ++ optionals cfg.nix.optimise.automatic [
        "nix-optimise rewrites the store on flash daily"
      ]
      ++
        optionals
          (
            cfg.hardware.enableAllHardware
            || cfg.hardware.enableAllFirmware
            || cfg.hardware.enableRedistributableFirmware
          )
          [
            "sd-image pulls in all hardware support and redistributable firmware"
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
      ++ optionals ((kernel.structuredExtraConfig.MTD_NAND_SUNXI or null) == null) [
        "kernel cannot attach the NAND before the initrd mounts the root"
      ]
      ++
        optionals (nand != (uBoot.drvPath == evaluated.${name}.pkgs.uboot-allwinner.uBootCHIPNand.drvPath))
          [
            "U-Boot does not match the root storage"
          ]
      ++ optionals (nand && !hasInfix "CONFIG_FASTBOOT_FLASH_NAND_TRIMFFS=y" (uBoot.extraConfig or "")) [
        "fastboot programs all-0xFF pages that UBI expects to stay erased"
      ]
      ++ optionals (nand != elem "ubi.mtd=rootfs" cfg.boot.kernelParams) [
        "UBI attach parameter does not match the root storage"
      ]
      ++ optionals (nand != (cfg.fileSystems."/".fsType == "ubifs")) [
        "root filesystem does not match the root storage"
      ]
      ++ optionals (nand && cfg.sdImage.expandOnBoot) [
        "first boot tries to grow a partition on UBI"
      ]
      ++ optionals (nand != (cfg.systemd.services ? ubihealthd)) [
        "NAND health watchdog does not match the root storage"
      ]
      ++ optionals (nand && !(hasInfix "sunxi-fel" nandFlash && hasInfix "flash rootfs" nandFlash)) [
        "NAND flasher does not load U-Boot over FEL and flash the root over fastboot"
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
