_self: super: {
  yggdrasil = super.yggdrasil.overrideAttrs (oldAttrs: {
    version = "0-unstable-2026-10-19";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "yggdrasil-go";
      rev = "290efc1101a47b1128549730ac7ec609b3603d66";
      hash = "sha256-ykI1lRjt39+ty6OfDFT3vb3THmcG7F9ZTxqIIYr5cPY=";
    };
    vendorHash = null;

    passthru = (oldAttrs.passthru or { }) // {
      updateScript = super.nix-update-script {
        extraArgs = [
          "--flake"
          "--version=branch"
          "--version-regex=v?(.*-unstable-.*)"
        ];
      };
    };
  });
}
