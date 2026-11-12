{
  pkgs,
  self,
  system,
}:

let
  inherit (pkgs.lib) elem;

  evaluated = self.lib.nixosSystem {
    inherit system;
    modules = [
      {
        nixpkgs.overlays = [
          (_final: prev: { justBeforeConsumer = prev.just; })
        ];
      }
    ];
  };

  checkFlags = evaluated.pkgs.justBeforeConsumer.checkFlags;
in

if
  elem "--skip=non_unicode::warn_for_non_unicode_invocation_directory" checkFlags
  && elem "--skip=non_unicode::warn_for_non_unicode_justfile_path" checkFlags
then
  pkgs.writeText "omnixiah-overlay-order" "OK"
else
  throw "Consumer overlays run before Omnixiah's just overlay"
