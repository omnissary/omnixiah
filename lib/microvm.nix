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
        self.nixosProfiles.base
        {
          networking.hostName = mkDefault "omnixiah-${name}";
          nixpkgs.overlays = [ self.overlays.default ];
        }
      ]
      ++ modules;
    };
}
