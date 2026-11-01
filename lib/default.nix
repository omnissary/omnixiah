{
  inputs,
  lib,
  profiles,
}:

let
  inherit (builtins)
    attrNames
    intersectAttrs
    removeAttrs
    ;
  inherit (lib) concatStringsSep mkDefault nixosSystem;

  flakeLib = import ./flakes.nix;

  omnixiahLib = {
    dns = inputs.dns.lib;
    nixosSystem =
      args:
      let
        rootFlake = args.rootFlake or inputs.self;
      in
      nixosSystem (
        (removeAttrs args [ "rootFlake" ])
        // {
          modules = args.modules or [ ];
          extraModules = [
            profiles.base
            {
              omnixiah.nix.sources.system = mkDefault rootFlake.outPath;
              system.extraDependencies = flakeLib.inputSources rootFlake;
            }
          ]
          ++ (args.extraModules or [ ]);
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
