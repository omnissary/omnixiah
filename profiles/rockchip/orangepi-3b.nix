{ lib, pkgs, ... }:

let
  inherit (lib) mkDefault;
in

{
  imports = [ ./. ];

  hardware.rockchip.uBoot = mkDefault pkgs.uboot-rockchip.uBootOrangePi3B;

  environment.etc."orangepi-release".text = "BOARD=orangepi3b";
}
