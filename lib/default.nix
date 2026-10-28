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
in
if collidingLibNames == [ ] then
  lib // omnixiahLib
else
  throw "Omnixiah lib collides with nixpkgs lib: ${concatStringsSep ", " collidingLibNames}"
