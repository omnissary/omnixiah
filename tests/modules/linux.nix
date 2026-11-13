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
  kernelFor = version: pkgs.${"linuxPackages_${replaceStrings [ "." ] [ "_" ] version}"}.kernel;

  default = pkgs.linuxPackages.kernel;
  versioned = kernelFor (majorMinor default.version);
  custom = (pkgs.linuxPackagesFor pkgs.linuxKernel.kernels.linux_default).kernel;
  board = pkgs.linuxPackages_rockchip.kernel;
  latest = pkgs.linuxPackages_latest.kernel;
  latestVersion = majorMinor latest.version;

  patchNames = kernel: map (patch: patch.name) kernel.kernelPatches;
  hasPatchesOnce =
    version: kernel:
    all (
      family:
      all (
        name: length (filter (patchName: patchName == name) (patchNames kernel)) == 1
      ) patchExpectations.${version}.${family}
    ) (attrNames patchExpectations.${version});

  versionErrors = concatMap (
    version:
    if hasPatchesOnce version (kernelFor version) then
      [ ]
    else
      [ "Linux ${version} has duplicate or missing patches" ]
  ) (attrNames patchExpectations);

  errors =
    versionErrors
    ++ (
      if hasAttr latestVersion patchExpectations then
        [ ]
      else
        (if (tryEval pkgs.perf.drvPath).success then [ ] else [ "perf cannot evaluate" ])
        ++ (if (tryEval latest.src.outPath).success then [ ] else [ "kernel source cannot evaluate" ])
        ++ (if (tryEval latest.drvPath).success then [ "unsupported kernel derivation evaluated" ] else [ ])
    )
    ++ (
      if default.drvPath == versioned.drvPath then [ ] else [ "default and versioned kernels differ" ]
    )
    ++ (if custom.drvPath == default.drvPath then [ ] else [ "linuxPackagesFor omits patches" ])
    ++ (
      if hasPatchesOnce (majorMinor board.version) board then
        [ ]
      else
        [ "board kernel has duplicate or missing patches" ]
    );
in
if errors == [ ] then
  pkgs.writeText "omnixiah-linux-kernel-patches" "OK"
else
  throw (concatStringsSep "; " errors)
