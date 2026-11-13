_self: super:
let
  inherit (builtins) any filter hasAttr;
  inherit (super.lib.versions) majorMinor;

  patchSets = {
    "6.18" = import ./6.18.nix;
  };

  patchKernel =
    kernel:
    let
      version = majorMinor kernel.version;
      patches =
        if hasAttr version patchSets then
          patchSets.${version}
        else
          throw "Omnixiah has no kernel patch set for Linux ${version}";
      uniqPatches = filter (
        patch: !(any (existing: existing.name == patch.name) kernel.kernelPatches)
      ) patches;
    in
    if hasAttr version patchSets && uniqPatches == [ ] then
      kernel
    else
      kernel.override (old: {
        kernelPatches = old.kernelPatches ++ uniqPatches;
      });
in
{
  kernelPackagesExtensions = super.kernelPackagesExtensions ++ [
    (_: kernelPrev: { kernel = patchKernel kernelPrev.kernel; })
  ];
}
