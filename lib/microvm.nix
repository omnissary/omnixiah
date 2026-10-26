{
  inputs,
  self,
}:

let
  inherit (inputs.nixpkgs.lib) mkDefault nixosSystem;
in

{
  mkMicrovmProfile =
    {
      name,
      system,
      modules,
      ...
    }:

    nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs self;
      };

      modules = [
        inputs.microvm.nixosModules.microvm
        self.profiles.base.module
        {
          networking.hostName = mkDefault "omnixiah-${name}";
        }
      ]
      ++ modules;
    };
}
