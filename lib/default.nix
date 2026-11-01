{
  inputs,
  lib,
  profiles,
}:

let
  inherit (builtins)
    attrNames
    intersectAttrs
    ;
  inherit (lib) concatStringsSep nixosSystem;

  flakeLib = import ./flakes.nix;

  omnixiahLib = {
    dns = inputs.dns.lib;
    nixosSystem =
      args:
      nixosSystem (
        args
        // {
          modules = args.modules or [ ];
          extraModules = [ profiles.base ] ++ (args.extraModules or [ ]);
        }
      );
    tests = import ../tests/metadata.nix;
  };

  collidingLibNames = attrNames (removeAttrs (intersectAttrs lib omnixiahLib) [ "nixosSystem" ]);
  collidingFlakeNames = attrNames (intersectAttrs lib.flakes flakeLib);
in
if collidingLibNames == [ ] && collidingFlakeNames == [ ] then
  lib // omnixiahLib // { flakes = lib.flakes // flakeLib; }
else
  throw "Omnixiah lib collides with nixpkgs lib: ${
    concatStringsSep ", " (collidingLibNames ++ collidingFlakeNames)
  }"
