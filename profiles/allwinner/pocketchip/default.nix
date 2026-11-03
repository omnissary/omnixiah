{ lib, pkgs, ... }:

let
  inherit (lib) mkDefault;

  consoleKeyMap = pkgs.runCommand "pocketchip.map" { } ''
    gzip -dc ${pkgs.kbd}/share/keymaps/i386/qwerty/us.map.gz > $out
    cat ${./console.map} >> $out
  '';
in

{
  imports = [ ../chip ];

  hardware.deviceTree.overlays = [
    {
      name = "pocketchip";
      dtsFile = ./overlay.dts;
    }
  ];

  console.keyMap = consoleKeyMap;

  services = {
    xserver.xkb = {
      layout = mkDefault "pocketchip";
      extraLayouts.pocketchip = {
        description = "PocketCHIP";
        languages = [ "eng" ];
        symbolsFile = ./xkb-symbols;
      };
    };

    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="event*", DRIVERS=="sun4i-ts", ENV{LIBINPUT_CALIBRATION_MATRIX}="-1 0 1 0 -1.18 1.09 0 0 1"
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness /sys/class/backlight/%k/bl_power"
    '';

    upower = {
      enable = mkDefault true;
      criticalPowerAction = mkDefault "PowerOff";
    };
  };
}
