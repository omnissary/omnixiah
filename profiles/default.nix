{ nixosProfiles }:

{
  minimal = {
    inherit (nixosProfiles.minimal) description;
    system = "x86_64-linux";
    modules = [
      nixosProfiles.microvm.module
      nixosProfiles.minimal.module
    ];
  };
}
