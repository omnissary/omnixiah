final: _prev: {
  gpgmail = final.callPackage (
    {
      coreutils,
      fetchFromGitHub,
      gnupg,
      lib,
      makeWrapper,
      python3Packages,
      stdenv,
    }:

    stdenv.mkDerivation {
      name = "gpgmail";
      src = fetchFromGitHub {
        owner = "jnphilipp";
        repo = "gpgmail";
        rev = "09167dfd4d2d8a81ee7d68c2e35c187349cf2881";
        hash = "sha256-9T+8wUJTg66FV7gyyWh5oTTiksNJOpyyxjLja3Ebqpo=";
      };

      buildInputs = [ python3Packages.python ];
      nativeBuildInputs = [
        makeWrapper
        python3Packages.wrapPython
      ];
      pythonPath = [ python3Packages.python-gnupg ];

      buildPhase = ''
        patchShebangs .
      '';
      installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          for program in gpgmail gpgmail-postfix; do
        install -Dm755 "$program" "$out/bin/$program"
            wrapProgram "$out/bin/$program" --prefix PATH : ${
              lib.makeBinPath [
                coreutils
                gnupg
              ]
            }
          done

          runHook postInstall
      '';

      postFixup = ''
        wrapPythonProgramsIn $out/bin "$out $pythonPath"
      '';
    }
  ) { };
}
