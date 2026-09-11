_self: super: {
  protoc-gen-grpc-capabilities = super.buildGoModule {
    name = "protoc-gen-grpc-capabilities";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "protoc-gen-grpc-capabilities";
      rev = "1a0777f3a9d94fce9d418e1d65f42cfc1250537a";
      hash = "sha256-A8i4AoSaPmu8dn580Y0h7Nqfcdr1b2NKfz4TWbR78dw=";
    };
    vendorHash = "sha256-7VKaA1NtSr0nF0hdsY1Ax4miq6CNXqn6Tpzt4E0eojM=";
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "." ];
    doCheck = false;
  };
}
