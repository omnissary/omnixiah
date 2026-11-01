{
  inputs,
  lib,
}:

let
  inherit (builtins) toJSON;
  inherit (lib)
    concatMapStringsSep
    mapAttrs'
    mkBefore
    mkDefault
    nameValuePair
    ;
  inherit (import ../lib/flakes.nix) inputSources;
in
{
  base =
    { config, pkgs, ... }:
    let
      inherit (pkgs) writeText;
      cfg = config.omnixiah.nix;
      overlaysFile = writeText "omnixiah-overlays.nix" ''
        let
          inherit (builtins) getFlake;
        in
        [
          ${concatMapStringsSep "\n" (
            entry: ''(getFlake "${entry.flake}").overlays.${toJSON entry.name}''
          ) cfg.overlays}
        ]
      '';
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
        overlays = map (entry: entry.flake.overlays.${entry.name}) cfg.overlays;
      };
      omnixiah.nix = {
        overlays = mkBefore [ { flake = inputs.self; } ];
        sources.omnixiah = inputs.self.outPath;
      };
      nix.nixPath = [
        "nixpkgs=/etc/omnixiah/nixpkgs"
        "nixpkgs-overlays=/etc/omnixiah/overlays.nix"
        "/etc/omnixiah"
      ];
      environment.etc =
        mapAttrs' (name: source: nameValuePair "omnixiah/${name}" { inherit source; }) cfg.sources
        // {
          "omnixiah/nixpkgs".source = pkgs.path;
          "omnixiah/overlays.nix".source = overlaysFile;
        };
      system.extraDependencies = inputSources inputs.self;
    };

  debug = ./debug.nix;
  microvm = ./microvm.nix;
  qemu = ./qemu.nix;
}
