final: _prev: {
  nix-cage = final.callPackage (
    {
      bubblewrap,
      fetchFromGitea,
      lib,
      makeWrapper,
      nix,
      nix-update-script,
      python3,
      stdenvNoCC,
    }:

    stdenvNoCC.mkDerivation {
      pname = "nix-cage";
      version = "0-unstable-2026-06-02";
      src = fetchFromGitea {
        domain = "git.tatikoma.dev";
        owner = "corpix";
        repo = "nix-cage";
        rev = "d42ed598bfb24fbfb4b0d131ddd07d7429c81094";
        hash = "sha256-b3c9O9FFU2hrS3lSfD3Q/t4hj0f2/dX4zlPcCpiWS0A=";
      };

      nativeBuildInputs = [ makeWrapper ];
      buildInputs = [ python3 ];

      buildPhase = ''
        patchShebangs .
      '';

      installPhase = ''
          runHook preInstall

        install -Dm755 nix-cage "$out/bin/nix-cage"
          wrapProgram "$out/bin/nix-cage" --prefix PATH : ${
            lib.makeBinPath [
              bubblewrap
              nix
            ]
          }

          runHook postInstall
      '';

      passthru.updateScript = nix-update-script {
        extraArgs = [
          "--flake"
          "--version=branch"
          "--version-regex=(0-unstable-.*)"
        ];
      };

      meta = {
        homepage = "https://github.com/corpix/nix-cage";
        description = "Sandboxed environments with nix-shell";
        longDescription = ''
          Sandboxed environments with bwrap and nix-shell
        '';
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
      };
    }
  ) { };
}
