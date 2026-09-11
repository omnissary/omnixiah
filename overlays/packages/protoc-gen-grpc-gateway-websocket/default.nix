_self: super: {
  protoc-gen-grpc-gateway-websocket = super.buildGoModule {
    name = "protoc-gen-grpc-gateway-websocket";

    src = super.fetchFromGitea {
      domain = "git.tatikoma.dev";
      owner = "corpix";
      repo = "protoc-gen-grpc-gateway-websocket";
      rev = "8f9f86a7c647ad4cab2f619a251451460230ed55";
      hash = "sha256-RFsXTneXP5v7iczPJutmDJn5vBZSXwOUolljatQJjy4=";
    };
    vendorHash = "sha256-D2Mtajv0xdo7cyZmLridRJfOVeSmBcjcJDMWdDs1K0k=";
    ldflags = [
      "-s"
      "-w"
    ];
    subPackages = [ "." ];
    doCheck = false;
  };
}
