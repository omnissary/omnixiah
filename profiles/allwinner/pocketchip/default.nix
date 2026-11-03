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

  # NTC's 4.4 kernel triggered the TCA8418 interrupt on low level
  # (pocketchip-keypad-patch); overlay.dts uses a falling edge. If keys
  # stick or drop, switch it to IRQ_TYPE_LEVEL_LOW first.
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

    # Mainline sun4i-ts ignores the touchscreen-inverted-x/y properties in
    # overlay.dts, so the matrix flips both axes; the Y scale and offset are
    # tuned values from NextThingCo/chip-configs, not measured here.
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
