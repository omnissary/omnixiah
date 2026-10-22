{ nixosProfiles }:

{
  minimal = {
    description = "Minimal Omnixiah system";
    system = "x86_64-linux";
    modules = [
      nixosProfiles.microvm.module
    ];
  };
}
