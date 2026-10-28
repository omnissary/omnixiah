{
  inputs,
  lib,
  overlay,
}:

let
  inherit (lib) mkBefore mkDefault;
in
{
  base = {
    key = "omnixiah/profiles/base";
    imports = [
      inputs.disko.nixosModules.default
      inputs.home-manager.nixosModules.default
      inputs.sops.nixosModules.default
      ./base.nix
    ];
    nixpkgs = {
      config.allowUnfree = mkDefault true;
      overlays = mkBefore [ overlay ];
    };
  };

  debug = ./debug.nix;
  microvm = ./microvm.nix;
  qemu = ./qemu.nix;
}
