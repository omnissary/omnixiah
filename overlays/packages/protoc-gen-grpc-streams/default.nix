_self: super: {
  protoc-gen-grpc-streams = super.buildGoModule {
    name = "protoc-gen-grpc-streams";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "protoc-gen-grpc-streams";
      rev = "b935591f4a1b09540c781a6b4aa7590e56b964bc";
      hash = "sha256-CpAEaL/Cc9iqyxQ/UK5FzFvs44mvfysh94yNm4xzxgg=";
    };
    vendorHash = "sha256-zD7wGWH7frhX43nnXT/0YplQ3lCdKliER66kn2PvRH0=";
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "." ];
    doCheck = false;
  };
}
