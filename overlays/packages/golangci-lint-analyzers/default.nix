_self: super: {
  golangci-lint-analyzers = super.buildGoModule {
    pname = "golangci-lint-analyzers";
    version = "0-unstable-2026-02-09";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "golangci-lint-analyzers";
      rev = "67e161afece0208acf68fee7a53a6e8e6121875d";
      hash = "sha256-zTz9KnbZSWCxCcBEvtN3qutDusaRFUOQNmHN1GtoFEI=";
    };
    vendorHash = null;
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "cmd/exhaustive" ];
    doCheck = false;

    passthru.updateScript = super.nix-update-script {
      extraArgs = [
        "--flake"
        "--version=branch"
        "--version-regex=(0-unstable-.*)"
      ];
    };
  };
}
