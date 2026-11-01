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
  overlayFor =
    entry:
    if entry.flake != null then
      entry.flake.overlays.${entry.name}
    else
      (import entry.path).${entry.name};
  overlayExpression =
    entry:
    if entry.flake != null then
      ''(getFlake "${entry.flake}").overlays.${toJSON entry.name}''
    else
      ''(import "${entry.path}").${toJSON entry.name}'';
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
          ${concatMapStringsSep "\n" overlayExpression cfg.overlays}
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
        overlays = map overlayFor cfg.overlays;
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
      assertions = map (entry: {
        assertion = (entry.flake != null) != (entry.path != null);
        message = "An Omnixiah Nix overlay must specify exactly one of flake or path.";
      }) cfg.overlays;
      system.extraDependencies = inputSources inputs.self;
    };

  debug = ./debug.nix;
  microvm = ./microvm.nix;
  qemu = ./qemu.nix;
}
