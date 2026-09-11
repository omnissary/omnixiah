final: _prev: {
  xresources = final.callPackage (
    { stdenvNoCC }:

    stdenvNoCC.mkDerivation {
      name = "xresources";

      dontUnpack = true;

      installPhase = ''
        runHook preInstall

        install -Dm644 ${./XResources} "$out/XResources"

        runHook postInstall
      '';
    }
  ) { };
}
