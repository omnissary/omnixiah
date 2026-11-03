{ lib, pkgs, ... }:

let
  inherit (lib) mkDefault;

  rtl8723bsFirmware = pkgs.runCommand "rtl8723bs-firmware" { } ''
    mkdir -p $out/lib/firmware/rtlwifi $out/lib/firmware/rtl_bt
    cp ${pkgs.linux-firmware}/lib/firmware/rtlwifi/rtl8723bs* $out/lib/firmware/rtlwifi/
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8723bs* $out/lib/firmware/rtl_bt/
  '';
in

{
  imports = [ ./. ];

  hardware = {
    allwinner.uBoot = mkDefault pkgs.uboot-allwinner.uBootCHIP;
    deviceTree = {
      name = "allwinner/sun5i-r8-chip.dtb";
      filter = "sun5i-r8-chip.dtb";
      overlays = [
        {
          name = "pocketchip";
          dtsFile = ./pocketchip.dts;
        }
      ];
    };
    firmware = [ rtl8723bsFirmware ];
  };

  boot.initrd.availableKernelModules = [
    "ehci_platform"
    "ohci_platform"
    "phy_sun4i_usb"
    "sd_mod"
    "uas"
    "usb_storage"
  ];
}
