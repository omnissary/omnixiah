final: _prev: {
  bcnc = final.callPackage (
    {
      lib,
      python3Packages,
      fetchFromGitHub,
      fetchPypi,
      nix-update-script,
    }:

    let
      pythonPackages = python3Packages;
      inherit (pythonPackages)
        buildPythonApplication
        buildPythonPackage
        numpy
        opencv-python
        pillow
        pyglm
        pyopengl
        pyserial
        scipy
        setuptools
        svgelements
        tkinter
        tkinter-gl
        wheel
        ;

      shxparser = buildPythonPackage rec {
        pname = "shxparser";
        version = "0.0.2";

        src = fetchPypi {
          inherit pname version;
          hash = "sha256-hUHkvOYodoIsk/OVnn9pCe8b+DUmkbNDus2qqbkv8nA=";
        };

        pyproject = true;
        build-system = [
          setuptools
          wheel
        ];
      };

    in
    buildPythonApplication rec {
      pname = "bCNC";
      version = "2dc769ee801a00e33418ed6c0b707d9c9ce83d76";

      src = fetchFromGitHub {
        owner = "vlachoudis";
        repo = "bCNC";
        rev = version;
        hash = "sha256-p1hydSQjL0Di1WKf1CLqgz+nNZ5RhtHcVR77rikmC64=";
      };

      pyproject = true;
      build-system = [
        setuptools
        wheel
      ];

      # FIXME: Add darwin-specific dependencies
      dependencies = [
        tkinter
        numpy
        pyserial
        svgelements
        shxparser
        pillow
        pyglm
        pyopengl
        tkinter-gl
        opencv-python
        scipy
      ];

      passthru.updateScript = nix-update-script {
        extraArgs = [
          "--flake"
          "--version=branch"
        ];
      };

      meta = {
        description = "GRBL CNC command sender, autoleveler and g-code editor";
        homepage = "https://github.com/eraserhd/bCNC-nix";
        license = lib.licenses.publicDomain;
        platforms = lib.platforms.all;
        maintainers = [ lib.maintainers.eraserhd ];
      };
    }
  ) { };
}
