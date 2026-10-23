self: super:
let
  inherit (self)
    fetchFromGitHub
    python3Packages
    ;
  inherit (self.lib)
    filter
    cmakeBool
    makeBinPath
    getLib
    ;

  pythonDeps = with python3Packages; [
    defusedxml
    networkx
    ladybug-core
    ladybug-radiance
    pysolar
  ];
  snapshotVersion = "0-unstable-2026-10-23";
in
{
  freecad-git = super.freecad.overrideAttrs (oldAttrs: {
    version = snapshotVersion;

    src = fetchFromGitHub {
      owner = "FreeCAD";
      repo = "FreeCAD";
      rev = "7f643c369dee071a9fa5058c831572ec48bbdd50";
      hash = "sha256-/ewUjbLy9AXT75NjZ48DLgX8dx4Q7NarLE0K9HwOUVA=";
      fetchSubmodules = true;
    };

    cmakeFlags = oldAttrs.cmakeFlags ++ [
      (cmakeBool "ENABLE_DEVELOPER_TESTS" false)
    ];

    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
      self.makeWrapper
    ];

    buildInputs = oldAttrs.buildInputs ++ pythonDeps;

    qtWrapperArgs = oldAttrs.qtWrapperArgs ++ [
      "--prefix PATH : ${makeBinPath [ self.gmsh ]}"
      "--prefix PYTHONPATH : ${python3Packages.makePythonPath pythonDeps}"
      "--set COIN_FREETYPE2_LIBNAME ${getLib self.freetype}/lib/libfreetype.so.6"
      "--set COIN_FONTCONFIG_LIBNAME ${getLib self.fontconfig}/lib/libfontconfig.so.1"
      "--set COIN_GLU_LIBNAME ${getLib self.libGLU}/lib/libGLU.so.1"
    ];

    patches = filter (
      value:
      let
        name = baseNameOf value;
      in
      name == "0001-NIXOS-don-t-ignore-PYTHONPATH.patch"
    ) oldAttrs.patches;

    postPatch = "";

    # The Qt hook has already wrapped these using makeCWrapper.
    # Add an outer shell wrapper because LADYBUG_TOOLS_FOLDER must
    # be calculated from the launching user's runtime environment.
    postFixup = (oldAttrs.postFixup or "") + ''
      for program in FreeCAD FreeCADCmd; do
        target="$out/bin/.$program-ladybug-wrapper-target"

        mv "$out/bin/$program" "$target"

        makeWrapper \
          "$target" \
          "$out/bin/$program" \
          --run 'export LADYBUG_TOOLS_FOLDER="''${XDG_DATA_HOME:-$HOME/.local/share}/ladybug_tools"'
      done
    '';

    versionCheckProgram = self.writeShellScript "freecad-git-version-check" ''
      "$1" --version --safe-mode && printf 'Nix snapshot %s\n' '${snapshotVersion}'
    '';

    passthru = (oldAttrs.passthru or { }) // {
      updateScript = self.nix-update-script {
        extraArgs = [
          "--flake"
          "--version=branch"
          "--version-regex=(0-unstable-.*)"
        ];
      };
    };
  });
}
