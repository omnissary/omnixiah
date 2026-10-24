_self: super: {
  yggdrasil = super.yggdrasil.overrideAttrs (oldAttrs: {
    version = "0-unstable-1970-01-01";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "yggdrasil-go";
      rev = "72e7e11015496570c8ef985c8615424dccd230e3";
      hash = "sha256-v0u1giw9Widdsxm+58+WE/iKtSBdaVrVHeeYZSYm2bI=";
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
