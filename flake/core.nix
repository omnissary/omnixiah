{
  inputs,
  lib,
  ...
}:

let
  inherit (lib) genAttrs;

  defaultOverlay = import ../overlays { inherit inputs; };
  profiles = import ../profiles {
    inherit inputs lib;
    overlay = defaultOverlay;
  };
  extendedLib = import ../lib {
    inherit inputs lib profiles;
  };

  supportedSystems = import inputs.systems;
  packagesBySystem = genAttrs supportedSystems (
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [ defaultOverlay ];
    }
  );
in
{
  flake = {
    modules = import ../modules { inherit lib; };
    overlays = {
      default = defaultOverlay;
      omnixiah = defaultOverlay;
    };
    inherit profiles;
    lib = extendedLib;
    pkgs = packagesBySystem;
  };

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = packagesBySystem.${system};
    };
}
