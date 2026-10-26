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
      version = "1.0.0-unstable-2026-10-26";
      src = fetchFromGitea {
        domain = "git.tatikoma.dev";
        owner = "corpix";
        repo = "nix-cage";
        rev = "7c0eeca4cd09db0809505d3a33719e5706e633fb";
        hash = "sha256-xxpC+A1NA2nwAoVHkGF0KhmqXGOPDPDUIz6z09ByokA=";
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
          "--version-regex=v?(.*-unstable-.*)"
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
