{ pkgs }:

let
  inherit (builtins)
    all
    attrNames
    filter
    hasAttr
    length
    map
    tryEval
    ;
  inherit (pkgs.lib) concatMap concatStringsSep replaceStrings;
  inherit (pkgs.lib.versions) majorMinor;

  patchExpectations = import ./linux-patches.nix;
  kernelForVersion =
    version: pkgs.${"linuxPackages_${replaceStrings [ "." ] [ "_" ] version}"}.kernel;

  defaultKernel = pkgs.linuxPackages.kernel;
  versionedKernel = kernelForVersion (majorMinor defaultKernel.version);
  linuxPackagesForKernel = (pkgs.linuxPackagesFor pkgs.linuxKernel.kernels.linux_default).kernel;
  rockchipKernel = pkgs.linuxPackages_rockchip.kernel;
  latestKernel = pkgs.linuxPackages_latest.kernel;
  latestVersion = majorMinor latestKernel.version;

  patchNames = kernel: map (patch: patch.name) kernel.kernelPatches;
  hasExpectedPatchesOnce =
    version: kernel:
    all (
      family:
      all (
        name: length (filter (patchName: patchName == name) (patchNames kernel)) == 1
      ) patchExpectations.${version}.${family}
    ) (attrNames patchExpectations.${version});

  versionedKernelErrors = concatMap (
    version:
    if hasExpectedPatchesOnce version (kernelForVersion version) then
      [ ]
    else
      [ "Linux ${version} has duplicate or missing patches" ]
  ) (attrNames patchExpectations);

  errors =
    versionedKernelErrors
    ++ (
      if hasAttr latestVersion patchExpectations then
        [ ]
      else
        (if (tryEval pkgs.perf.drvPath).success then [ ] else [ "perf cannot evaluate" ])
        ++ (if (tryEval latestKernel.src.outPath).success then [ ] else [ "kernel source cannot evaluate" ])
        ++ (
          if (tryEval latestKernel.drvPath).success then
            [ "unsupported kernel derivation evaluated" ]
          else
            [ ]
        )
    )
    ++ (
      if defaultKernel.drvPath == versionedKernel.drvPath then
        [ ]
      else
        [ "default and versioned kernels differ" ]
    )
    ++ (
      if linuxPackagesForKernel.drvPath == defaultKernel.drvPath then
        [ ]
      else
        [ "linuxPackagesFor omits patches" ]
    )
    ++ (
      if hasExpectedPatchesOnce (majorMinor rockchipKernel.version) rockchipKernel then
        [ ]
      else
        [ "Rockchip kernel has duplicate or missing patches" ]
    );
in
if errors == [ ] then
  pkgs.writeText "omnixiah-linux-kernel-patches" "OK"
else
  throw (concatStringsSep "; " errors)
