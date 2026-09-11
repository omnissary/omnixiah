_self: super: {
  starlark-lsp = super.buildGoModule {
    pname = "starlark-lsp";
    version = "0-unstable-2026-07-26";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "starlark-lsp";
      rev = "560812e01d435631d87c03bce2cb3972a3bfadcc";
      hash = "sha256-+fu7Tko9USK/gbwdjho3LaoRl5B97xAiSCHwm8J3bxs=";
    };
    vendorHash = "sha256-PqMed2czM5BxnQs9O641W9MlrVZe0Uv+bII1KK4h974=";

    subPackages = [ "cmd/starlark-lsp" ];
    doCheck = false;
  };
}
