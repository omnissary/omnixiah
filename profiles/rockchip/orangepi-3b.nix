{ lib, pkgs, ... }:

let
  inherit (lib) mkDefault;
in

{
  imports = [ ./. ];

  hardware.rockchip.uBoot = mkDefault pkgs.ubootOrangePi3B;

  environment.etc."orangepi-release".text = "BOARD=orangepi3b";
}
