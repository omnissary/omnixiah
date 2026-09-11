final: _prev: {
  bcnc = final.callPackage (
    {
      lib,
      python3Packages,
      fetchFromGitHub,
      fetchPypi,
    }:

    let
      pythonPackages = python3Packages;
      inherit (pythonPackages)
        buildPythonApplication
        buildPythonPackage
        numpy
        opencv-python
        pillow
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
      version = "5aab96b12f9f96794abfc47af661ba5fc7767d4b";

      src = fetchFromGitHub {
        owner = "vlachoudis";
        repo = "bCNC";
        rev = version;
        hash = "sha256-OqwwTphZlCM4NLDh8vGEgjLw+c76UscDp0r8C5kEOrw=";
      };

      prePatch = ''
        substituteInPlace setup.py \
          --replace-fail "opencv-python==4.5.5.64" "opencv-python>=4.5.5.64"
      '';

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
        tkinter-gl
        opencv-python
        scipy
      ];

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
