final: _prev: {
  qrxclip = final.callPackage (
    {
      bash,
      feh,
      lib,
      makeWrapper,
      qrencode,
      stdenvNoCC,
      xclip,
    }:

    stdenvNoCC.mkDerivation {
      name = "qrxclip";
      src = ./src;

      nativeBuildInputs = [ makeWrapper ];

      buildPhase = ":";
      installPhase = ''
        runHook preInstall

        install -Dm755 "$src/qrxclip" "$out/bin/qrxclip"
        wrapProgram "$out/bin/qrxclip" --prefix PATH : ${
          lib.makeBinPath [
            bash
            feh
            qrencode
            xclip
          ]
        }

        runHook postInstall
      '';
    }
  ) { };
}
