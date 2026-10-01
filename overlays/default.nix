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
      _final: _prev: {
        unstable = (inputs.nix.overlays.default nixFinal nixPrev).nix;
      }
    );
  };

  xlibreOverlay =
    xlibreFinal: xlibrePrev:
    let
      overlayNames = [
        "xlibre-xserver"
      ]
      ++ filter (name: name != "xlibre-xserver") (attrNames inputs.nixpkgs-xlibre.overlays);
    in
    xlibrePrev.lib.composeManyExtensions (map (
      name: inputs.nixpkgs-xlibre.overlays.${name}
    ) overlayNames) xlibreFinal xlibrePrev;

in
composeManyExtensions (
  [
    pythonPackageOverlay
    xlibreOverlay
    nixVersionsOverlay
  ]
  ++ inputsOverlays
  ++ packageOverlays
) final prev
