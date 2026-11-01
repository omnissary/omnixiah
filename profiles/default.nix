{
  inputs,
  lib,
  overlay,
}:

let
  inherit (lib) mkAfter mkBefore mkDefault;
  inherit (import ../lib/flakes.nix) inputSources;
in
{
  base =
    { pkgs, ... }:
    let
      inherit (pkgs) writeText;
    in
    {
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
      nix.nixPath = mkAfter [
        "nixpkgs=${pkgs.path}"
        "nixpkgs-overlays=${writeText "omnixiah-nixpkgs-overlays.nix" ''
          let
            inherit (builtins) getFlake;
          in
          [ (getFlake "${inputs.self}").overlays.default ]
        ''}"
      ];
      system.extraDependencies = inputSources inputs.self;
    };

  debug = ./debug.nix;
  microvm = ./microvm.nix;
  qemu = ./qemu.nix;
}
