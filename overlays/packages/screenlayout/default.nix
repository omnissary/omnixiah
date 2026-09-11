final: _prev: {
  screenlayout = final.callPackage (
    {
      lib,
      makeWrapper,
      racket,
      stdenvNoCC,
    }:

    stdenvNoCC.mkDerivation {
      name = "screenlayout";
      src = ./src;

      nativeBuildInputs = [ makeWrapper ];

      buildPhase = ":";
      installPhase = ''
        runHook preInstall

        install -Dm755 "$src/screenlayout" "$out/bin/screenlayout"
        wrapProgram "$out/bin/screenlayout" --prefix PATH : ${lib.makeBinPath [ racket ]}

        runHook postInstall
      '';
    }
  ) { };
}
