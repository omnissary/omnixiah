{ inputs }:
final: prev:
let
  inherit (builtins)
    attrNames
    filter
    lessThan
    listToAttrs
    readDir
    ;
  inherit (prev.lib)
    composeManyExtensions
    filterAttrs
    hasPrefix
    mapAttrs
    mkDefault
    sort
    ;

  directoryNames =
    path: sort lessThan (attrNames (filterAttrs (_: type: type == "directory") (readDir path)));

  packageOverlays =
    let
      packageNames = directoryNames ./packages;
    in
    map (name: import (./packages + "/${name}")) packageNames;

  inputsOverlays = [
    inputs.deploy.overlays.default
  ];

  pythonPackageOverlay =
    let
      packageNames = directoryNames ./python-packages;
    in
    _final: pythonPackagesPrev: {
      pythonPackagesExtensions = (pythonPackagesPrev.pythonPackagesExtensions or [ ]) ++ [
        (
          pythonFinal: pythonPrev:
          (listToAttrs (
            map (name: {
              inherit name;
              value = pythonFinal.callPackage (./python-packages + "/${name}") { };
            }) packageNames
          ))
        )
      ];
    };

  nixVersionsOverlay = nixFinal: nixPrev: {
    nixVersions = nixPrev.nixVersions.extend (
      _final: nixVersionsPrev:
      mapAttrs (
        name: value:
        if hasPrefix "nixComponents_" name && value ? overrideScope then
          value.overrideScope (_final: _prev: { inherit (nixFinal) git; })
        else
          value
      ) nixVersionsPrev
      // {
        unstable = (inputs.nix.overlays.default nixFinal nixPrev).nix;
      }
    );
  };

  nixosAnywhereOverlay = nixosAnywhereFinal: _prev: {
    nixos-anywhere = nixosAnywhereFinal.callPackage (inputs.nixos-anywhere + "/src") { };
  };

  omnixiahOverlay = omnixiahFinal: _prev: {
    omnixiah = {
      runNixOSTest =
        testModule:
        omnixiahFinal.testers.runNixOSTest {
          imports = [
            {
              defaults.imports = [ inputs.self.profiles.base ];
              node.pkgsReadOnly = mkDefault false;
            }
            testModule
          ];
        };
    };
  };

  xlibreOverlay =
    xlibreFinal: xlibrePrev:
    let
      overlayNames = [
        "xlibre-xserver"
      ]
      ++ filter (name: name != "xlibre-xserver") (attrNames inputs.xlibre.overlays);
    in
    composeManyExtensions (map (
      name: inputs.xlibre.overlays.${name}
    ) overlayNames) xlibreFinal xlibrePrev;

in
composeManyExtensions (
  [
    pythonPackageOverlay
    xlibreOverlay
    nixVersionsOverlay
    nixosAnywhereOverlay
    omnixiahOverlay
  ]
  ++ inputsOverlays
  ++ packageOverlays
) final prev
