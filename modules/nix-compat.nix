{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.omnixiah.nix = {
    overlays = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            flake = mkOption {
              type = types.nullOr types.raw;
              default = null;
              description = "Flake that exports the overlay.";
            };
            path = mkOption {
              type = types.nullOr types.pathInStore;
              default = null;
              description = "Importable source file that exports the overlay.";
            };
            name = mkOption {
              type = types.str;
              default = "default";
              description = "Name of the overlay exported by the flake or source file.";
            };
          };
        }
      );
      default = [ ];
      description = "Flake overlays applied to the system and legacy Nix commands.";
    };

    sources = mkOption {
      type = types.attrsOf types.pathInStore;
      default = { };
      description = "Sources exposed by name below /etc/omnixiah.";
    };
  };
}
