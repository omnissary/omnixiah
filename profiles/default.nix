{ profiles }:

{
  minimal = {
    description = "Minimal Omnixiah system";
    system = "x86_64-linux";
    modules = [
      profiles.microvm.module
    ];
  };
}
