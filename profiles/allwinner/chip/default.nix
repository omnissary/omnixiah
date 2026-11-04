{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkDefault mkForce mkOverride;

  nand = config.hardware.allwinner.chip.storage == "nand";

  rtl8723bsFirmware = pkgs.runCommand "rtl8723bs-firmware" { } ''
    mkdir -p $out/lib/firmware/rtlwifi $out/lib/firmware/rtl_bt
    cp ${pkgs.linux-firmware}/lib/firmware/rtlwifi/rtl8723bs* $out/lib/firmware/rtlwifi/
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8723bs* $out/lib/firmware/rtl_bt/
  '';
in

{
  imports = [
    ../.
    ./nand.nix
  ];

  hardware = {
    allwinner.uBoot = mkDefault (
      if nand then pkgs.uboot-allwinner.uBootCHIPNand else pkgs.uboot-allwinner.uBootCHIP
    );
    deviceTree = {
      name = "sun5i-r8-chip.dtb";
      filter = "sun5i-r8-chip.dtb";
    };
    firmware = [ rtl8723bsFirmware ];
  };

  boot = {
    kernelParams = [ "fw_devlink=permissive" ];
    initrd.availableKernelModules = [
      "ehci_platform"
      "ohci_platform"
      "phy_sun4i_usb"
      "sd_mod"
      "uas"
      "usb_storage"
    ];
    extraModprobeConfig = ''
      options r8723bs rtw_power_mgnt=0 rtw_ips_mode=0 rtw_wifi_spec=1
    '';
  };

  networking.networkmanager.wifi = {
    macAddress = mkDefault "permanent";
    scanRandMacAddress = mkDefault false;
    powersave = mkDefault false;
  };

  services.logind.settings.Login = {
    HandlePowerKey = mkDefault "ignore";
    HandlePowerKeyLongPress = mkDefault "ignore";
  };

  services.journald.settings.Journal = {
    Storage = mkDefault "volatile";
    RuntimeMaxUse = mkDefault "16M";
  };

  boot.tmp.useTmpfs = mkDefault true;

  nix.optimise.automatic = mkOverride 900 false;

  services.fwupd.enable = mkOverride 900 false;

  system.tools.nixos-generate-config.enable = mkDefault false;

  zramSwap.enable = mkDefault true;

  # Always cross-built and deployed remotely, nix never evaluates on device;
  # pinned input sources and nixpkgs would take hundreds of MiB of the NAND.
  system.extraDependencies = mkForce [ ];
  nixpkgs.flake.source = mkForce null;
  environment.etc."omnixiah/nixpkgs".enable = false;
}
