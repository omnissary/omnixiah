{
  minimal = {
    description = "Minimal Omnixiah MicroVM profile";
    system = "x86_64-linux";
    modules = [
      ./vm.nix
      ./minimal.nix
    ];
  };
}
