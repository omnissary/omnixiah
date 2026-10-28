{
  inputs,
  lib,
  self,
  ...
}:

let
  inherit (lib)
    filter
    genAttrs
    hasSuffix
    mapAttrs'
    mkDefault
    nameValuePair
    ;
  inherit (self.lib) nixosSystem;

  supportedSystems = import inputs.systems;
  linuxSystems = filter (hasSuffix "-linux") supportedSystems;
  microvmConfigurations = genAttrs linuxSystems (
    system:
    nixosSystem {
      inherit system;
      specialArgs = { inherit inputs self; };
      modules = [
        inputs.microvm.nixosModules.microvm
        self.profiles.microvm
        {
          networking.hostName = mkDefault "omnixiah-microvm";
        }
      ];
    }
  );
in
{
  flake.nixosConfigurations = mapAttrs' (
    system: microvmConfiguration: nameValuePair "microvm-${system}" microvmConfiguration
  ) microvmConfigurations;

  perSystem =
    { pkgs, system, ... }:
    let
      microvmConfiguration = microvmConfigurations.${system};
      microvmRunner = microvmConfiguration.config.microvm.declaredRunner;
      microvmApp = {
        type = "app";
        program = "${microvmRunner}/bin/microvm-run";
        meta.description = "Run an Omnixiah MicroVM";
      };
    in
    {
      apps = {
        default = microvmApp;
        microvm = microvmApp;
      };

      packages = {
        default = microvmRunner;
        microvm = microvmRunner;
      };

      checks.microvm-eval = pkgs.writeText "omnixiah-microvm-eval" microvmConfiguration.config.system.build.toplevel.drvPath;
    };
}
