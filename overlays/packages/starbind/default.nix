_self: super: {
  starbind = super.buildGoModule {
    pname = "starbind";
    version = "0-unstable";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "starbind";
      rev = "e81f4f8c5a628fe4ad78fcbcf12a0fafd50be3d4";
      hash = "sha256-AOaeQnB4+9Q+CKb4l0irPgkN9ynjxMqPVaO8k1B8HXo=";
    };
    vendorHash = null;
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "cmd/starbind" ];

    meta = {
      mainProgram = "starbind";
      description = "Generate Starlark bindings for Go code";
    };
  };
}
