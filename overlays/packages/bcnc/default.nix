final: _prev: {
  bcnc = final.callPackage (
    {
      lib,
      stdenv,
      python3Packages,
      fetchFromGitHub,
      fetchPypi,
      nix-update-script,
      tkgl,
      tcl-8_6,
      tcl-9_0,
      tk-8_6,
      tk-9_0,
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
        wheel
        ;

      # nixpkgs builds tkinter on Python 3.14 against Tcl/Tk 9 but tkgl against
      # 8.6, so Tcl 9 looks for libtcl9Tkgl and fails to load the widget.
      tkinter-gl = pythonPackages.tkinter-gl.override {
        tkgl =
          let
            tcl9 = pythonPackages.pythonAtLeast "3.14";
          in
          tkgl.override {
            tcl = if tcl9 then tcl-9_0 else tcl-8_6;
            tk = if tcl9 then tk-9_0 else tk-8_6;
          };
      };

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
      version = "0-unstable-2026-10-23";

      src = fetchFromGitHub {
        owner = "vlachoudis";
        repo = "bCNC";
        rev = "2dc769ee801a00e33418ed6c0b707d9c9ce83d76";
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
      ]
      # upstream skips opencv on 32-bit arm; both are optional imports
      ++ lib.optionals (!stdenv.hostPlatform.isAarch32) [
        opencv-python
        scipy
      ];
      pythonRemoveDeps = lib.optionals stdenv.hostPlatform.isAarch32 [ "opencv-python" ];

      passthru.updateScript = nix-update-script {
        extraArgs = [
          "--flake"
          "--version=branch"
          "--version-regex=(0-unstable-.*)"
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
