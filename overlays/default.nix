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

  packageNames = directoryNames ./packages;
  pythonPackageNames = directoryNames ./python-packages;

  packageOverlays = map (name: import (./packages + "/${name}")) packageNames;

  pythonPackageOverlay = _final: pythonPackagesPrev: {
    pythonPackagesExtensions = (pythonPackagesPrev.pythonPackagesExtensions or [ ]) ++ [
      (
        pythonFinal: pythonPrev:
        (listToAttrs (
          map (name: {
            inherit name;
            value = pythonFinal.callPackage (./python-packages + "/${name}") { };
          }) pythonPackageNames
        ))
        // {
          aiohttp = pythonPrev.aiohttp.overridePythonAttrs (
            _: prev.lib.optionalAttrs prev.stdenv.hostPlatform.isAarch64 { doCheck = false; }
          );
          httpcore2 = pythonPrev.httpcore2.overridePythonAttrs (
            _: prev.lib.optionalAttrs prev.stdenv.hostPlatform.isAarch64 { doCheck = false; }
          );
          pycairo = pythonPrev.pycairo.overridePythonAttrs (old: {
            disabledTests = (old.disabledTests or [ ]) ++ [ "test_fspaths" ];
          });
          "python-ulid" = pythonPrev.python-ulid.overridePythonAttrs (
            _: prev.lib.optionalAttrs prev.stdenv.hostPlatform.isAarch64 { doCheck = false; }
          );
        }
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

  espOverlay =
    espFinal: espPrev:
    let
      overlay = inputs.nixpkgs-esp.overlays.default espFinal espPrev;
    in
    {
      inherit (overlay)
        esp-idf-esp32
        esp-idf-full
        esp8266-nonos-sdk
        esp8266-rtos-sdk
        gcc-xtensa-lx106-elf-bin
        qemu-esp32
        ;
    };

  pascalLanguageServerOverlay =
    if inputs.pascal-language-server ? overlays then
      inputs.pascal-language-server.overlays.default
    else
      pascalFinal: _: {
        pascal-language-server =
          inputs.pascal-language-server.packages.${pascalFinal.stdenv.hostPlatform.system}.pascal-language-server
            or inputs.pascal-language-server.packages.${pascalFinal.stdenv.hostPlatform.system}.default;
      };

in

composeManyExtensions (
  [
    inputs.deploy.overlays.default
    xlibreOverlay
    espOverlay
    pascalLanguageServerOverlay
    pythonPackageOverlay
    nixVersionsOverlay
  ]
  ++ packageOverlays
) final prev
