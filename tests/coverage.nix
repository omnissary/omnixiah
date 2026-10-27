{
  pkgs,
  self,
  system,
}:

let
  inherit (builtins) concatStringsSep filter;

  covered = configuration: configuration ? omnixiah && configuration.omnixiah.base;

  node =
    (pkgs.omnixiah.runNixOSTest {
      name = "coverage";
      nodes.machine = { };
      testScript = "";
    }).nodes.machine;

  entryPoints = {
    "lib.nixosSystem" = self.nixosConfigurations."microvm-${system}".config;
    "pkgs.omnixiah.runNixOSTest" = node;
  };

  uncovered = filter (name: !covered entryPoints.${name}) (builtins.attrNames entryPoints);
in

if uncovered == [ ] then
  pkgs.writeText "omnixiah-coverage" "OK"
else
  throw "Entry points build systems without the base profile: ${concatStringsSep ", " uncovered}"
