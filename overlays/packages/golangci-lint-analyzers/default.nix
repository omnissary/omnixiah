_self: super: {
  golangci-lint-analyzers = super.buildGoModule {
    name = "golangci-lint-analyzers";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "golangci-lint-analyzers";
      rev = "4253a6fd67a7af246573c3c36a9aa277e1b194a4";
      hash = "sha256-5eC/3FgUlIYWxGMPIiN5j73IVkeJK5WEOcV/OjurTpY=";
    };
    vendorHash = null;
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "cmd/exhaustive" ];
    doCheck = false;
  };
}
